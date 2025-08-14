import os
import platform
import subprocess
import sys
from pathlib import Path

# =======================
# CONFIGURAÇÕES
# =======================
CONTAINER_NAME = "oracle-xe"
IMAGE = "gvenzl/oracle-xe:latest"
ORACLE_PASSWORD = "SenhaForte123"  # ajuste se quiser
HOST_PORT_DB = "1521"
HOST_PORT_EM = "5500"

# Caminho da PASTA onde está o .DMP (não o arquivo), no Windows:
WIN_DMP_DIR = r"C:\Users\Kaiqu\Desktop\dev\DB"  # <- AJUSTE AQUI SE MUDAR A PASTA

# Nome do SERVICE padrão na imagem
ORACLE_SERVICE = "XEPDB1"

# Diretório dentro do container onde o dump ficará acessível
CONTAINER_DPDUMP = "/opt/oracle/dpdump"

# Dados de conexão que vamos imprimir
DB_INFO = {
    "host": "localhost",
    "port": HOST_PORT_DB,
    "service": ORACLE_SERVICE,
    "user_admin": "SYSTEM",
    "password": ORACLE_PASSWORD,
}

# =======================
# HELPERS
# =======================
def run(cmd, check=True, capture_output=False, shell=False):
    """Executa um comando e retorna (returncode, stdout, stderr)."""
    try:
        if capture_output:
            res = subprocess.run(cmd, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=shell)
            return res.returncode, res.stdout.strip(), res.stderr.strip()
        else:
            res = subprocess.run(cmd, check=check, shell=shell)
            return res.returncode, "", ""
    except subprocess.CalledProcessError as e:
        return e.returncode, e.stdout.decode("utf-8", "ignore") if e.stdout else "", e.stderr.decode("utf-8", "ignore") if e.stderr else ""
    except FileNotFoundError:
        print("Erro: comando não encontrado. Verifique se o Docker está instalado e no PATH.")
        sys.exit(1)

def docker_available():
    code, out, err = run(["docker", "--version"], check=False, capture_output=True)
    return code == 0

def container_exists():
    code, out, err = run(["docker", "ps", "-a", "--filter", f"name={CONTAINER_NAME}", "--format", "{{.Names}} {{.Status}}"], check=False, capture_output=True)
    return CONTAINER_NAME in out if out else False

def container_running():
    code, out, err = run(["docker", "ps", "--filter", f"name={CONTAINER_NAME}", "--format", "{{.Names}} {{.Status}}"], check=False, capture_output=True)
    return CONTAINER_NAME in out if out else False

def start_container():
    # Sobe o container com a pasta montada
    mount = f"{WIN_DMP_DIR}:{CONTAINER_DPDUMP}"
    print(f"Subindo container '{CONTAINER_NAME}' com volume: {mount}")
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
        print("Falha ao subir o container.")
        if err: print(err)
        if out: print(out)
        sys.exit(1)
    print("Container iniciado.")

def ensure_running():
    if not container_exists():
        start_container()
    elif not container_running():
        print("Container existe, mas está parado. Iniciando...")
        code, out, err = run(["docker","start", CONTAINER_NAME], check=False, capture_output=True)
        if code != 0:
            print("Não consegui iniciar o container:", err or out)
            sys.exit(1)
        print("Container iniciado.")
    else:
        print("Container já está em execução.")

def exec_in_container(command, interactive=False):
    """
    Executa um comando dentro do container.
    interactive=True usa -it (TTY) para comandos como sqlplus.
    """
    base = ["docker","exec"]
    if interactive:
        base += ["-it"]
    base += [CONTAINER_NAME]
    if isinstance(command, str):
        cmd = base + ["bash","-lc", command]
    else:
        # lista vira bash -lc "cmd joined"
        cmd_str = " ".join(command)
        cmd = base + ["bash","-lc", cmd_str]
    return run(cmd, check=False, capture_output=not interactive, shell=False)

def ensure_directory_dp_dir():
    print("Garantindo DIRECTORY dp_dir dentro do Oracle...")
    sql = f"""
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE OR REPLACE DIRECTORY dp_dir AS '{CONTAINER_DPDUMP}';
GRANT READ, WRITE ON DIRECTORY dp_dir TO SYSTEM;
"""
    # Usa sqlplus silencioso (-s) para rodar script
    command = f'echo "{sql}" | sqlplus -s system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE}'
    code, out, err = exec_in_container(command)
    if code != 0:
        print("Aviso: não consegui garantir o DIRECTORY dp_dir. Saída:")
        print(out or err)

def list_dmp_files():
    dmp_files = []
    try:
        p = Path(WIN_DMP_DIR)
        if p.exists():
            dmp_files = [f.name for f in p.iterdir() if f.is_file() and f.suffix.lower()==".dmp"]
    except Exception as e:
        print("Não consegui listar a pasta de dumps:", e)
    return dmp_files

def import_dump(dump_filename, remap_schema=None, remap_tablespace=None, version=None):
    print(f"Iniciando import do dump: {dump_filename}")
    params = [
        f"impdp system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE}",
        f"directory=dp_dir",
        f"dumpfile={dump_filename}",
        f"logfile=import.log"
    ]
    if remap_schema:
        params.append(f"remap_schema={remap_schema}")
    if remap_tablespace:
        params.append(f"remap_tablespace={remap_tablespace}")
    if version:
        params.append(f"version={version}")

    cmd = " ".join(params)
    # Import não precisa de TTY; vamos capturar saída
    code, out, err = exec_in_container(cmd, interactive=False)
    print(out)
    if code != 0:
        print("Import terminou com erro:")
        print(err)

def print_db_info():
    print("\n=== Oracle XE em Docker ===")
    print(f"host: {DB_INFO['host']}")
    print(f"port: {DB_INFO['port']}")
    print(f"service: {DB_INFO['service']}")
    print(f"usuário admin: {DB_INFO['user_admin']}")
    print(f"senha: {DB_INFO['password']}")
    print("===========================\n")

def open_sqlplus_interactive():
    print("Abrindo SQL*Plus interativo (CTRL+C para sair do SQL*Plus)...")
    # -it precisa de TTY; usamos modo interativo e não capturamos a saída
    cmd = f"sqlplus system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE}"
    # Passa interactive=True para alocar TTY
    exec_in_container(cmd, interactive=True)

def stop_and_remove_container():
    print("Parando container...")
    run(["docker","stop", CONTAINER_NAME], check=False)
    print("Removendo container...")
    run(["docker","rm", CONTAINER_NAME], check=False)
    print("Container parado e removido.")

# =======================
# MENU
# =======================
def menu():
    if not docker_available():
        print("Docker não encontrado. Instale o Docker Desktop e tente novamente.")
        sys.exit(1)

    # Garante que a pasta de dumps existe
    p = Path(WIN_DMP_DIR)
    if not p.exists():
        print(f"A pasta de dumps não existe: {WIN_DMP_DIR}")
        sys.exit(1)

    while True:
        print("\n=== MENU ORACLE XE ===")
        print("[1] Rodar database (subir/verificar container), importar dump (opcional) e/ou abrir SQL*Plus")
        print("[2] Parar e fechar container, e sair")
        choice = input("Escolha: ").strip()

        if choice == "1":
            ensure_running()
            print_db_info()
            ensure_directory_dp_dir()

            # Oferece importar dump agora
            dmp_files = list_dmp_files()
            if dmp_files:
                print("Dumps disponíveis na pasta montada:")
                for i, f in enumerate(dmp_files, start=1):
                    print(f"  {i}) {f}")
                resp = input("Deseja importar um dump agora? (s/n): ").strip().lower()
                if resp == "s":
                    idx = input("Digite o número do arquivo: ").strip()
                    try:
                        idx = int(idx)
                        dump = dmp_files[idx-1]
                    except Exception:
                        print("Opção inválida.")
                        dump = None
                    if dump:
                        # Pergunta remap (opcional)
                        remap_schema = input("remap_schema (ex: USUARIO_ORIGEM:USUARIO_DESTINO) ou ENTER p/ pular: ").strip() or None
                        remap_tablespace = input("remap_tablespace (ex: OLD_TBS:USERS) ou ENTER p/ pular: ").strip() or None
                        version = input("version (ex: 12.2) ou ENTER p/ pular: ").strip() or None
                        import_dump(dump, remap_schema, remap_tablespace, version)

            # Oferece abrir SQL*Plus
            resp_sql = input("Abrir SQL*Plus interativo agora? (s/n): ").strip().lower()
            if resp_sql == "s":
                open_sqlplus_interactive()

        elif choice == "2":
            # Para e remove o container e sai
            stop_and_remove_container()
            print("Saindo...")
            break
        else:
            print("Opção inválida. Tente novamente.")

if __name__ == "__main__":
    menu()
