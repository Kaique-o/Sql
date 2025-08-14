
import json
import hashlib
import os
import subprocess
import sys
import time
from pathlib import Path

# =======================
# CONFIGURAÇÕES (ajuste se necessário)
# =======================
CONTAINER_NAME = "oracle-free"
IMAGE = "gvenzl/oracle-free:latest"
ORACLE_PASSWORD = "SenhaForte123"
HOST_PORT_DB = "1521"
HOST_PORT_EM = "5500"

# Pasta LOCAL onde ficam os .DMP (não o arquivo isolado)
WIN_DMP_DIR = r"C:\Users\Kaiqu\Desktop\dev\DB"

# Service name padrão do Oracle 23c Free
ORACLE_SERVICE = "FREEPDB1"

# Diretório dentro do container para os dumps
CONTAINER_DPDUMP = "/opt/oracle/dpdump"

# Arquivo de estado para saber se o DMP mudou
STATE_FILE = ".import_state.json"

# Dados de conexão (para exibir quando tudo estiver pronto)
DB_INFO = {
    "host": "localhost",
    "port": HOST_PORT_DB,
    "service": ORACLE_SERVICE,
    "user_admin": "SYSTEM",
    "password": ORACLE_PASSWORD,
}

# =======================
# UTILITÁRIOS
# =======================
def run(cmd, check=True, capture_output=False, shell=False):
    try:
        if capture_output:
            res = subprocess.run(cmd, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=shell)
            return res.returncode, res.stdout.strip(), res.stderr.strip()
        else:
            res = subprocess.run(cmd, check=check, shell=shell)
            return res.returncode, "", ""
    except subprocess.CalledProcessError as e:
        out = e.stdout if isinstance(e.stdout, str) else (e.stdout.decode("utf-8", "ignore") if e.stdout else "")
        err = e.stderr if isinstance(e.stderr, str) else (e.stderr.decode("utf-8", "ignore") if e.stderr else "")
        return e.returncode, out, err
    except FileNotFoundError:
        print("❌ Comando não encontrado. Verifique se o Docker está instalado e no PATH.")
        sys.exit(1)

def docker_available():
    code, _, _ = run(["docker", "--version"], check=False, capture_output=True)
    return code == 0

def ensure_directory(path: Path):
    path.mkdir(parents=True, exist_ok=True)

def image_exists(image: str) -> bool:
    code, out, _ = run(["docker", "image", "inspect", image], check=False, capture_output=True)
    return code == 0

def ensure_image(image: str):
    if not image_exists(image):
        print(f"📥 Baixando imagem Docker {image} (primeira vez em máquina nova)...")
        code, out, err = run(["docker", "pull", image], check=False, capture_output=True)
        if code != 0:
            print("❌ Falha ao baixar a imagem:", err or out)
            sys.exit(1)
        print("✅ Imagem baixada.")

def container_exists(name: str) -> bool:
    code, out, _ = run(["docker", "ps", "-a", "--filter", f"name={name}", "--format", "{{.Names}}"], check=False, capture_output=True)
    return name in (out or "")

def container_running(name: str) -> bool:
    code, out, _ = run(["docker", "ps", "--filter", f"name={name}", "--format", "{{.Names}}"], check=False, capture_output=True)
    return name in (out or "")

def start_container():
    mount = f"{WIN_DMP_DIR}:{CONTAINER_DPDUMP}"
    print(f"🚀 Subindo container '{CONTAINER_NAME}' com volume: {mount}")
    cmd = [
        "docker","run","-d",
        "--name", CONTAINER_NAME,
        "-p", f"{HOST_PORT_DB}:1521",
        "-p", f"{HOST_PORT_EM}:5500",
        "-e", f"ORACLE_PASSWORD={ORACLE_PASSWORD}",
        "-v", mount,
        IMAGE
    ]
    code, out, err = run(cmd, check=False, capture_output=True)
    if code != 0:
        print("❌ Falha ao subir o container.")
        print(err or out)
        sys.exit(1)
    print("✅ Container iniciado.")

def ensure_running():
    if not container_exists(CONTAINER_NAME):
        start_container()
    elif not container_running(CONTAINER_NAME):
        print("▶️ Iniciando container existente...")
        code, out, err = run(["docker","start", CONTAINER_NAME], check=False, capture_output=True)
        if code != 0:
            print("❌ Não consegui iniciar o container:", err or out)
            sys.exit(1)
        print("✅ Container em execução.")
    else:
        print("ℹ️ Container já está em execução.")

def exec_in_container(command: str, interactive=False):
    base = ["docker","exec"]
    if interactive:
        base += ["-it"]
    base += [CONTAINER_NAME, "bash", "-lc", command]
    return run(base, check=False, capture_output=not interactive, shell=False)

def wait_db_ready(timeout_sec=600, sleep_sec=5):
    print("⏳ Aguardando o banco ficar pronto para conexão...")
    start = time.time()
    while time.time() - start < timeout_sec:
        cmd = f'echo "select 1 from dual;" | sqlplus -s system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE}'
        code, out, _ = exec_in_container(cmd)
        if code == 0 and ("1" in (out or "")):
            print("✅ Banco pronto para usar.")
            return True
        time.sleep(sleep_sec)
    print("❌ Timeout esperando o banco ficar pronto.")
    return False

def ensure_directory_dp_dir():
    print("🛠️ Garantindo DIRECTORY dp_dir dentro do Oracle...")
    sql = f"""
CREATE OR REPLACE DIRECTORY dp_dir AS '{CONTAINER_DPDUMP}';
BEGIN
    EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY dp_dir TO SYSTEM';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1749 THEN
            NULL; -- Ignora ORA-01749 (grant para si mesmo)
        ELSE
            RAISE;
        END IF;
END;
/
"""
    command = f'echo "{sql}" | sqlplus -s system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE}'
    code, out, err = exec_in_container(command)
    if code != 0:
        print("⚠️ Aviso ao garantir DIRECTORY:", err or out)
    else:
        print("✅ DIRECTORY dp_dir garantido.")

def list_dmp_files():
    try:
        p = Path(WIN_DMP_DIR)
        return [f.name for f in p.iterdir() if f.is_file() and f.suffix.lower()==".dmp"]
    except Exception as e:
        print("❌ Erro listando dumps:", e)
        return []

def file_fingerprint(path: Path) -> str:
    """Gera uma assinatura baseada em tamanho + mtime para evitar custo de hash em arquivos grandes."""
    try:
        stat = path.stat()
        base = f"{path.name}|{stat.st_size}|{int(stat.st_mtime)}"
        return hashlib.sha256(base.encode("utf-8")).hexdigest()
    except FileNotFoundError:
        return ""

def load_state(folder: Path) -> dict:
    state_path = folder / STATE_FILE
    if state_path.exists():
        try:
            return json.loads(state_path.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}

def save_state(folder: Path, state: dict):
    state_path = folder / STATE_FILE
    state_path.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")

def import_dump_if_needed(dump_filename: str, folder: Path) -> bool:
    """Importa o dump apenas se mudou desde a última importação. Retorna True se importou, False se pulou."""
    dumps = list_dmp_files()
    if dump_filename not in dumps:
        print(f"❌ Dump '{dump_filename}' não encontrado em {folder}")
        return False

    state = load_state(folder)
    dump_path = folder / dump_filename
    current_fp = file_fingerprint(dump_path)
    last_fp = state.get("last_import_fp", "")

    if current_fp == last_fp:
        print("⏭️ Import pulado: o .DMP não mudou desde a última importação.")
        print("✅ Pronto para usar (sem necessidade de importar novamente).")
        return False

    # Executa impdp e acompanha o log em tempo real
    print(f"📦 Iniciando import do dump: {dump_filename}")
    # Garantir que log anterior não confunda saída
    exec_in_container(f"rm -f {CONTAINER_DPDUMP}/import.log")

    impdp_cmd = (
        f"impdp system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE} "
        f"directory=dp_dir dumpfile={dump_filename} logfile=import.log"
    )

    # Roda o impdp e faz tail do log até terminar (tail --pid encerra junto)
    # Se --pid não existir, ao menos veremos o log enquanto roda.
    cmd = f"""\
set -e
( {impdp_cmd} ) &
pid=$!
echo "📝 Acompanhando import.log (PID=$pid)..."
# espera o log aparecer
for i in $(seq 1 120); do
  [ -f {CONTAINER_DPDUMP}/import.log ] && break
  sleep 1
done
# tail com --pid se disponível
if tail --help 2>/dev/null | grep -q -- "--pid"; then
  tail -f {CONTAINER_DPDUMP}/import.log --pid $pid
else
  tail -f {CONTAINER_DPDUMP}/import.log &
  t=$!
  wait $pid || true
  kill $t 2>/dev/null || true
fi
wait $pid
"""
    code, out, err = exec_in_container(cmd)
    # Mostra última linha do log pra indicar status
    _, tail_out, _ = exec_in_container(f"tail -n 5 {CONTAINER_DPDUMP}/import.log")
    if tail_out:
        print(tail_out)

    if code != 0:
        print("❌ Import terminou com erro.")
        return False

    # Atualiza state
    state["last_import_fp"] = current_fp
    state["last_import_file"] = dump_filename
    save_state(folder, state)
    print("✅ Import concluído e estado atualizado. Pronto para usar.")
    return True

def print_db_ready_banner():
    print("\n================= PRONTO PARA USAR =================")
    print("Conecte-se com as seguintes credenciais:")
    print(f"  host: {DB_INFO['host']}")
    print(f"  port: {DB_INFO['port']}")
    print(f"  service: {DB_INFO['service']}")
    print(f"  usuário admin: {DB_INFO['user_admin']}")
    print(f"  senha: {DB_INFO['password']}")
    print("====================================================\n")

def open_sqlplus_interactive():
    print("🔗 Abrindo SQL*Plus interativo (CTRL+C para sair)...")
    cmd = f"sqlplus system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE}"
    # Interativo = aloca TTY
    base = ["docker","exec","-it",CONTAINER_NAME,"bash","-lc",cmd]
    subprocess.call(base)

def setup_new_machine():
    """Passo 3: Setup de Docker/Imagem/Container para máquina nova."""
    if not docker_available():
        print("❌ Docker não encontrado. Instale o Docker Desktop e execute novamente.")
        sys.exit(1)
    ensure_directory(Path(WIN_DMP_DIR))
    ensure_image(IMAGE)
    if not container_exists(CONTAINER_NAME):
        start_container()
    else:
        print("ℹ️ Container já existe.")
    if not container_running(CONTAINER_NAME):
        ensure_running()
    if not wait_db_ready():
        sys.exit(1)
    ensure_directory_dp_dir()
    print_db_ready_banner()

# =======================
# MENU
# =======================
def menu():
    if not docker_available():
        print("❌ Docker não encontrado. Instale o Docker Desktop e tente novamente.")
        sys.exit(1)

    dump_folder = Path(WIN_DMP_DIR)
    if not dump_folder.exists():
        print(f"❌ Pasta de dumps não existe: {WIN_DMP_DIR}")
        sys.exit(1)

    while True:
        print("\n=== MENU ORACLE 23c FREE ===")
        print("[1] Fazer TUDO que é necessário sempre (subir/verificar Docker + DB, esperar ficar pronto, garantir DIRECTORY)")
        print("[2] Importar DMP SOMENTE se mudou (caso necessário)")
        print("[3] Setup de Docker/Imagem/Container (máquina nova)")
        print("[4] Sair")
        choice = input("Escolha: ").strip()

        if choice == "1":
            ensure_image(IMAGE)
            ensure_running()
            if not wait_db_ready():
                continue
            ensure_directory_dp_dir()
            print_db_ready_banner()
            if input("Deseja abrir SQL*Plus agora? (s/n): ").strip().lower() == "s":
                open_sqlplus_interactive()

        elif choice == "2":
            ensure_image(IMAGE)
            ensure_running()
            if not wait_db_ready():
                continue
            ensure_directory_dp_dir()
            dumps = list_dmp_files()
            if not dumps:
                print(f"⚠️ Nenhum .DMP encontrado em {WIN_DMP_DIR}")
            else:
                print("Dumps disponíveis:")
                for i, f in enumerate(dumps, start=1):
                    print(f"  {i}) {f}")
                sel = input("Escolha o número do dump para verificar/importar: ").strip()
                try:
                    dump = dumps[int(sel)-1]
                except Exception:
                    print("Opção inválida.")
                    dump = None
                if dump:
                    import_dump_if_needed(dump, dump_folder)

        elif choice == "3":
            setup_new_machine()

        elif choice == "4":
            print("👋 Saindo...")
            break

        else:
            print("Opção inválida.")

if __name__ == "__main__":
    menu()
