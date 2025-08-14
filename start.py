
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
def _decode(b):
    if b is None:
        return ""
    try:
        return b.decode("utf-8", "replace").strip()
    except Exception:
        try:
            return b.decode("latin-1", "replace").strip()
        except Exception:
            return ""

def run(cmd, check=True, capture_output=False, shell=False):
    try:
        if capture_output:
            res = subprocess.run(cmd, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=False, shell=shell)
            return res.returncode, _decode(res.stdout), _decode(res.stderr)
        else:
            res = subprocess.run(cmd, check=check, shell=shell)
            return res.returncode, "", ""
    except subprocess.CalledProcessError as e:
        out = _decode(getattr(e, "stdout", b""))
        err = _decode(getattr(e, "stderr", b""))
        return e.returncode, out, err
    except FileNotFoundError:
        print("❌ Comando não encontrado. Verifique se o Docker está instalado e no PATH.")
        return 127, "", "command not found"

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
            return False
        print("✅ Imagem baixada.")
    return True

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
        return False
    print("✅ Container iniciado.")
    return True

def ensure_running():
    if not container_exists(CONTAINER_NAME):
        if not start_container():
            return False
    elif not container_running(CONTAINER_NAME):
        print("▶️ Iniciando container existente...")
        code, out, err = run(["docker","start", CONTAINER_NAME], check=False, capture_output=True)
        if code != 0:
            print("❌ Não consegui iniciar o container:", err or out)
            return False
        print("✅ Container em execução.")
    else:
        print("ℹ️ Container já está em execução.")
    return True

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

    print(f"📦 Iniciando import do dump: {dump_filename}")
    exec_in_container(f"rm -f {CONTAINER_DPDUMP}/import.log")

    impdp_cmd = (
        f"impdp system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE} "
        f"directory=dp_dir dumpfile={dump_filename} logfile=import.log"
    )

    cmd = f"""\
set -e
( {impdp_cmd} ) &
pid=$!
echo "📝 Acompanhando import.log (PID=$pid)..."
for i in $(seq 1 120); do
  [ -f {CONTAINER_DPDUMP}/import.log ] && break
  sleep 1
done
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
    _, tail_out, _ = exec_in_container(f"tail -n 5 {CONTAINER_DPDUMP}/import.log")
    if tail_out:
        print(tail_out)

    if code != 0:
        print("❌ Import terminou com erro.")
        return False

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
    base = ["docker","exec","-it",CONTAINER_NAME,"bash","-lc",cmd]
    subprocess.call(base)

def stop_container_only():
    print("🛑 Parando container (se estiver em execução)...")
    run(["docker","stop", CONTAINER_NAME], check=False)
    print("✅ Container parado. (Não removido)")

def setup_new_machine():
    if not docker_available():
        print("❌ Docker não encontrado. Instale o Docker Desktop e execute novamente.")
        return False
    ensure_directory(Path(WIN_DMP_DIR))
    if not ensure_image(IMAGE):
        return False
    if not container_exists(CONTAINER_NAME):
        if not start_container():
            return False
    else:
        print("ℹ️ Container já existe.")
    if not ensure_running():
        return False
    if not wait_db_ready():
        return False
    ensure_directory_dp_dir()
    print_db_ready_banner()
    return True

# ===== Helpers para correção (Opção 5) e Diagnóstico (Opção 6) =====

def summarize_ora_errors(log_path: str, tail_lines: int = 50):
    print("🔎 Resumo dos erros ORA- no log:")
    cmd_count = f"grep -o 'ORA-[0-9]\\\\+' {log_path} | sort | uniq -c | sort -nr | head -20"
    _, out1, _ = exec_in_container(cmd_count)
    print(out1 or "(nenhum ORA- encontrado)")
    print("\n📝 Últimas linhas do log:")
    _, out2, _ = exec_in_container(f"tail -n {tail_lines} {log_path}")
    print(out2 or "(log vazio)")

def recreate_user(user: str, password: str):
    sqlblock = f"""
WHENEVER SQLERROR CONTINUE
DROP USER {user} CASCADE;
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE USER {user} IDENTIFIED BY "{password}"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE TO {user};
GRANT CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER TO {user};
"""
    cmd = f"sqlplus -s system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE} <<'SQL'\n{sqlblock}\nSQL"
    code, out, err = exec_in_container(cmd)
    if code != 0:
        print("⚠️ Problema ao (re)criar usuário:", err or out)
    else:
        print(f"✅ Usuário {user} (re)criado com sucesso.")

def schema_only_import_fix(dump_filename: str, schema_src: str, user_dest: str, user_dest_pwd: str):
    print(f"📦 Import schema-only: dump={dump_filename}, schema_origem={schema_src}, destino={user_dest}")
    recreate_user(user_dest, user_dest_pwd)

    log_path = f"{CONTAINER_DPDUMP}/import_schema.log"
    exec_in_container(f"rm -f {log_path}")

    impdp_cmd = (
        f"impdp system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE} "
        f"directory=dp_dir dumpfile={dump_filename} logfile=import_schema.log "
        f"schemas={schema_src} remap_schema={schema_src}:{user_dest} "
        f"transform=segment_attributes:n "
        f"exclude=JOB,DB_LINK,SYNONYM,STATISTICS,GRANT"
    )

    cmd = f"""\
set -e
( {impdp_cmd} ) &
pid=$!
echo "📝 Acompanhando import_schema.log (PID=$pid)..."
for i in $(seq 1 120); do
  [ -f {log_path} ] && break
  sleep 1
done
if tail --help 2>/dev/null | grep -q -- "--pid"; then
  tail -f {log_path} --pid $pid
else
  tail -f {log_path} &
  t=$!
  wait $pid || true
  kill $t 2>/dev/null || true
fi
wait $pid
"""
    code, out, err = exec_in_container(cmd)
    summarize_ora_errors(log_path)
    if code != 0:
        print("❌ Import schema-only terminou com erro (ver resumo acima).")
        return False

    print("✅ Import schema-only concluído.")
    check_sql = f"""
set pages 100 lines 200 feedback off
SELECT table_name, num_rows FROM all_tables WHERE owner=upper('{user_dest}') ORDER BY num_rows DESC FETCH FIRST 20 ROWS ONLY;
"""
    cmd = f'echo "{check_sql}" | sqlplus -s system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE}'
    _, out, _ = exec_in_container(cmd)
    print("\n📊 Top 20 tabelas (num_rows):\n" + (out or "(sem retorno)"))
    return True

def diagnose_dump(dump_filename: str):
    print(f"🧪 Diagnóstico do dump: {dump_filename} (gerando DDL preview, sem alterar o banco)")
    ddl_path = f"{CONTAINER_DPDUMP}/ddl_preview.sql"
    log_path = f"{CONTAINER_DPDUMP}/diagnose.log"
    exec_in_container(f"rm -f {ddl_path} {log_path}")

    impdp_cmd = (
        f"impdp system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE} "
        f"directory=dp_dir dumpfile={dump_filename} "
        f"content=METADATA_ONLY sqlfile=ddl_preview.sql logfile=diagnose.log"
    )
    code, out, err = exec_in_container(impdp_cmd)
    _, tail_out, _ = exec_in_container(f"tail -n 20 {log_path}")
    print("📝 diagnose.log (últimas linhas):\n" + (tail_out or "(vazio)"))

    schema_extract = (
        f"awk 'match($0, /CREATE (TABLE|VIEW|SEQUENCE|PROCEDURE|FUNCTION|PACKAGE|TRIGGER|INDEX) \\\"([^\\\"]+)\\\"\\./, m){{print m[2]}}' {ddl_path} "
        "| sort | uniq -c | sort -nr | head -30"
    )
    _, schemas_out, _ = exec_in_container(schema_extract)

    tbs_extract = f"grep -o 'TABLESPACE \\\"[^\\\"]*\\\"' {ddl_path} | sed 's/TABLESPACE \\\"//;s/\\\"//' | sort | uniq -c | sort -nr"
    _, tbs_out, _ = exec_in_container(tbs_extract)

    dblinks_extract = f"grep -o 'DATABASE LINK \\\"[^\\\"]*\\\"' {ddl_path} | sed 's/DATABASE LINK \\\"//;s/\\\"//' | sort | uniq -c | sort -nr"
    _, dblink_out, _ = exec_in_container(dblinks_extract)

    print("\n📚 Schemas detectados no DDL (top 30 por ocorrência):")
    print(schemas_out or "(nenhum detectado)")

    print("\n💽 Tablespaces referenciadas no DDL:")
    print(tbs_out or "(nenhuma encontrada)")

    print("\n🔗 DB Links referenciados no DDL:")
    print(dblink_out or "(nenhum encontrado)")

    ts_sql = """
set pages 100 lines 200
COLUMN TABLESPACE_NAME FORMAT A30
SELECT TABLESPACE_NAME, STATUS, CONTENTS, BIGFILE FROM dba_tablespaces ORDER BY TABLESPACE_NAME;
"""
    cmd = f'echo "{ts_sql}" | sqlplus -s system/{ORACLE_PASSWORD}@localhost:{HOST_PORT_DB}/{ORACLE_SERVICE}'
    _, ts_out, _ = exec_in_container(cmd)
    print("\n🗄️ Tablespaces EXISTENTES no destino:")
    print(ts_out or "(sem retorno)")

    print("\n✅ Diagnóstico concluído. Use as infos acima para definir SCHEMA de origem, REMAP_SCHEMA e possíveis REMAP_TABLESPACE.")

# =======================
# MENU
# =======================
def menu():
    if not docker_available():
        print("❌ Docker não encontrado. Instale o Docker Desktop e tente novamente.")
        input("Pressione ENTER para sair...")
        return

    dump_folder = Path(WIN_DMP_DIR)
    if not dump_folder.exists():
        print(f"❌ Pasta de dumps não existe: {WIN_DMP_DIR}")
        input("Pressione ENTER para sair...")
        return

    while True:
        print("\n=== MENU ORACLE 23c FREE ===")
        print("[1] Fazer TUDO que é necessário sempre (subir/verificar Docker + DB, esperar ficar pronto, garantir DIRECTORY)")
        print("[2] Importar DMP SOMENTE se mudou (caso necessário) — retorna ao menu ao terminar")
        print("[3] Setup de Docker/Imagem/Container (máquina nova)")
        print("[4] Encerrar serviços (parar container) e SAIR")
        print("[5] Reimportar (schema-only) para corrigir erros comuns")
        print("[6] Diagnóstico do dump (DDL preview, schemas/tablespaces/links)")
        choice = input("Escolha: ").strip()

        if choice == "1":
            if not ensure_image(IMAGE):
                input("Pressione ENTER para voltar ao menu...")
                continue
            if not ensure_running():
                input("Pressione ENTER para voltar ao menu...")
                continue
            if not wait_db_ready():
                input("Pressione ENTER para voltar ao menu...")
                continue
            ensure_directory_dp_dir()
            print_db_ready_banner()
            if input("Deseja abrir SQL*Plus agora? (s/n): ").strip().lower() == "s":
                open_sqlplus_interactive()
            input("Pressione ENTER para voltar ao menu...")

        elif choice == "2":
            if not ensure_image(IMAGE):
                input("Pressione ENTER para voltar ao menu...")
                continue
            if not ensure_running():
                input("Pressione ENTER para voltar ao menu...")
                continue
            if not wait_db_ready():
                input("Pressione ENTER para voltar ao menu...")
                continue
            ensure_directory_dp_dir()
            dumps = list_dmp_files()
            if not dumps:
                print(f"⚠️ Nenhum .DMP encontrado em {WIN_DMP_DIR}")
                input("Pressione ENTER para voltar ao menu...")
                continue
            if len(dumps) == 1:
                dump = dumps[0]
                print(f"ℹ️ Apenas um dump encontrado. Usando: {dump}")
            else:
                print("Dumps disponíveis:")
                for i, f in enumerate(dumps, start=1):
                    print(f"  {i}) {f}")
                sel = input("Escolha o número do dump para verificar/importar: ").strip()
                try:
                    dump = dumps[int(sel)-1]
                except Exception:
                    print("Opção inválida.")
                    input("Pressione ENTER para voltar ao menu...")
                    continue

            try:
                import_dump_if_needed(dump, dump_folder)
                print_db_ready_banner()
            except KeyboardInterrupt:
                print("\n⚠️ Importação interrompida pelo usuário.")
            except Exception as e:
                print(f"❌ Erro inesperado na importação: {e}")
            finally:
                input("Pressione ENTER para voltar ao menu...")

        elif choice == "3":
            setup_new_machine()
            input("Pressione ENTER para voltar ao menu...")

        elif choice == "4":
            stop_container_only()
            print("👋 Encerrando execução...")
            break

        elif choice == "5":
            if not ensure_image(IMAGE):
                input("Pressione ENTER para voltar ao menu..."); continue
            if not ensure_running():
                input("Pressione ENTER para voltar ao menu..."); continue
            if not wait_db_ready():
                input("Pressione ENTER para voltar ao menu..."); continue
            ensure_directory_dp_dir()
            dumps = list_dmp_files()
            if not dumps:
                print(f"⚠️ Nenhum .DMP encontrado em {WIN_DMP_DIR}")
                input("Pressione ENTER para voltar ao menu..."); continue
            if len(dumps) == 1:
                dump = dumps[0]
                print(f"ℹ️ Apenas um dump encontrado. Usando: {dump}")
            else:
                print("Dumps disponíveis:")
                for i, f in enumerate(dumps, start=1):
                    print(f"  {i}) {f}")
                sel = input("Escolha o número do dump: ").strip()
                try:
                    dump = dumps[int(sel)-1]
                except Exception:
                    print("Opção inválida."); input("Pressione ENTER para voltar ao menu..."); continue

            schema_src = input("Schema de ORIGEM (padrão: SKWCLOUD): ").strip() or "SKWCLOUD"
            user_dest = input("Usuário DESTINO (padrão: SKY_USER): ").strip() or "SKY_USER"
            user_dest_pwd = input(f"Senha do usuário {user_dest} (padrão: MinhaSenha!1): ").strip() or "MinhaSenha!1"

            try:
                ok = schema_only_import_fix(dump, schema_src, user_dest, user_dest_pwd)
                if ok:
                    print_db_ready_banner()
            except KeyboardInterrupt:
                print("\n⚠️ Reimportação interrompida pelo usuário.")
            except Exception as e:
                print(f"❌ Erro inesperado na reimportação: {e}")
            finally:
                input("Pressione ENTER para voltar ao menu...")

        elif choice == "6":
            if not ensure_image(IMAGE):
                input("Pressione ENTER para voltar ao menu..."); continue
            if not ensure_running():
                input("Pressione ENTER para voltar ao menu..."); continue
            if not wait_db_ready():
                input("Pressione ENTER para voltar ao menu..."); continue
            ensure_directory_dp_dir()
            dumps = list_dmp_files()
            if not dumps:
                print(f"⚠️ Nenhum .DMP encontrado em {WIN_DMP_DIR}")
                input("Pressione ENTER para voltar ao menu..."); continue
            if len(dumps) == 1:
                dump = dumps[0]
                print(f"ℹ️ Apenas um dump encontrado. Usando: {dump}")
            else:
                print("Dumps disponíveis:")
                for i, f in enumerate(dumps, start=1):
                    print(f"  {i}) {f}")
                sel = input("Escolha o número do dump: ").strip()
                try:
                    dump = dumps[int(sel)-1]
                except Exception:
                    print("Opção inválida."); input("Pressione ENTER para voltar ao menu..."); continue
            try:
                diagnose_dump(dump)
            except KeyboardInterrupt:
                print("\n⚠️ Diagnóstico interrompido pelo usuário.")
            except Exception as e:
                print(f"❌ Erro inesperado no diagnóstico: {e}")
            finally:
                input("Pressione ENTER para voltar ao menu...")

        else:
            print("Opção inválida.")
            input("Pressione ENTER para voltar ao menu...")

if __name__ == "__main__":
    menu()
