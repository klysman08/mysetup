# DS ENV

```bash
chmod +x ds-init.sh

# Criar projeto com Python 3.11 (padrão)
./ds-init.sh meu-projeto

# Ou especificar a versão do Python
./ds-init.sh meu-projeto 3.12
```

## Script ENV DS / ML

```bash
#!/usr/bin/env bash
# ==============================================================================
# ds-init.sh — Inicializador de projetos de Data Science / ML com UV
# Uso: bash ds-init.sh <nome-do-projeto> [versao-python]
# Exemplo: bash ds-init.sh meu-projeto 3.11
# ==============================================================================

set -euo pipefail

# ── Cores para output ──────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Validação de argumentos ────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Uso: $0 <nome-do-projeto> [versao-python]"
  echo "Exemplo: $0 meu-projeto 3.11"
  exit 1
fi

PROJECT_NAME="$1"
PYTHON_VERSION="${2:-3.11}"

# Validar nome do projeto (apenas letras, números, hífens e underscores)
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  log_error "Nome do projeto inválido. Use apenas letras, números, hífens e underscores."
fi

# ── Verificar se UV está instalado ─────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
  log_warn "UV não encontrado. Instalando..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.cargo/bin:$PATH"
  log_success "UV instalado com sucesso."
fi

# ── Verificar se o diretório já existe ────────────────────────────────────────
if [ -d "$PROJECT_NAME" ]; then
  log_error "Diretório '$PROJECT_NAME' já existe. Escolha outro nome."
fi

log_info "Criando projeto '$PROJECT_NAME' com Python $PYTHON_VERSION..."

# ── Inicializar projeto com UV ─────────────────────────────────────────────────
uv init "$PROJECT_NAME" --python "$PYTHON_VERSION" --no-workspace
cd "$PROJECT_NAME"

# Remover o hello.py gerado pelo uv init
rm -f hello.py

# ── Criar estrutura de pastas ──────────────────────────────────────────────────
log_info "Criando estrutura de diretórios..."

mkdir -p \
  data/raw \
  data/processed \
  data/external \
  data/interim \
  notebooks/exploratory \
  notebooks/modeling \
  notebooks/reports \
  src/"${PROJECT_NAME//-/_}" \
  models/trained \
  models/checkpoints \
  configs \
  tests \
  reports/figures \
  logs \
  scripts \
  docs

# ── Criar arquivos __init__.py ─────────────────────────────────────────────────
SRC_PKG="src/${PROJECT_NAME//-/_}"

touch "${SRC_PKG}/__init__.py"
touch "${SRC_PKG}/data.py"
touch "${SRC_PKG}/features.py"
touch "${SRC_PKG}/models.py"
touch "${SRC_PKG}/evaluate.py"
touch "${SRC_PKG}/utils.py"
touch "${SRC_PKG}/visualize.py"
touch tests/__init__.py
touch tests/test_data.py
touch tests/test_models.py

# ── Criar arquivos .gitkeep para pastas vazias ─────────────────────────────────
for dir in data/raw data/processed data/external data/interim \
            models/trained models/checkpoints \
            reports/figures logs; do
  touch "$dir/.gitkeep"
done

# ── Criar .gitignore ───────────────────────────────────────────────────────────
log_info "Criando .gitignore..."
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
*.so
*.egg
*.egg-info/
dist/
build/
.eggs/

# UV / Ambientes virtuais
.venv/
venv/
env/

# Jupyter
.ipynb_checkpoints/
*.ipynb_checkpoints

# Dados (não versionar dados brutos grandes)
data/raw/*
data/processed/*
data/external/*
data/interim/*
!data/**/.gitkeep

# Modelos treinados (geralmente grandes)
models/trained/*
models/checkpoints/*
!models/**/.gitkeep

# Logs e relatórios
logs/*.log
reports/figures/*
!reports/figures/.gitkeep

# Configurações locais e segredos
.env
.env.*
!.env.example
secrets/
*.key

# IDEs
.vscode/
.idea/
*.swp
*.swo
*.DS_Store

# MLflow / DVC / W&B
mlruns/
.dvc/
wandb/
EOF

# ── Criar .env.example ─────────────────────────────────────────────────────────
cat > .env.example << 'EOF'
# Exemplo de variáveis de ambiente
# Copie para .env e preencha com seus valores reais

PROJECT_NAME=__PROJECT_NAME__

# Caminhos
DATA_DIR=data/
MODELS_DIR=models/
LOGS_DIR=logs/

# Credenciais (nunca commite o .env real)
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# MLFLOW_TRACKING_URI=
# WANDB_API_KEY=
EOF
sed -i "s/__PROJECT_NAME__/$PROJECT_NAME/" .env.example

# ── Criar configs/config.yaml ──────────────────────────────────────────────────
cat > configs/config.yaml << EOF
project:
  name: $PROJECT_NAME
  version: "0.1.0"

data:
  raw_dir: data/raw
  processed_dir: data/processed
  external_dir: data/external
  interim_dir: data/interim

model:
  random_seed: 42
  test_size: 0.2
  validation_size: 0.1

training:
  epochs: 100
  batch_size: 32
  learning_rate: 0.001
  early_stopping_patience: 10

logging:
  level: INFO
  dir: logs/
EOF

# ── Criar Makefile ─────────────────────────────────────────────────────────────
cat > Makefile << 'EOF'
.PHONY: install sync test lint format clean jupyter

install:
	uv sync

sync:
	uv sync --all-extras

test:
	uv run pytest tests/ -v

lint:
	uv run ruff check src/ tests/

format:
	uv run ruff format src/ tests/

clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".ipynb_checkpoints" -exec rm -rf {} +

jupyter:
	uv run jupyter lab notebooks/
EOF

# ── Criar notebook de exploração inicial ──────────────────────────────────────
log_info "Criando notebook exploratório inicial..."
cat > notebooks/exploratory/01_data_exploration.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": ["# Exploração de Dados\n", "\nNotebook inicial para análise exploratória (EDA)."]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "sns.set_theme(style='whitegrid')\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Carregue seus dados aqui\n",
    "# df = pd.read_csv('../data/raw/dataset.csv')\n",
    "# df.head()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
  "language_info": {"name": "python", "version": "3.11.0"}
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# ── Atualizar pyproject.toml com dependências de DS/ML ───────────────────────
log_info "Configurando pyproject.toml..."
cat > pyproject.toml << EOF
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "Projeto de Data Science / Machine Learning"
readme = "README.md"
requires-python = ">=$PYTHON_VERSION"
dependencies = []

[project.optional-dependencies]
dev = [
    "ipykernel",
    "jupyter",
    "jupyterlab",
    "ruff",
    "pytest",
    "pytest-cov",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
EOF

# ── Instalar dependências de data science ─────────────────────────────────────
log_info "Instalando dependências principais de DS/ML..."

uv add \
  pandas \
  numpy \
  scikit-learn \
  matplotlib \
  seaborn \
  plotly \
  pyyaml \
  python-dotenv \
  tqdm \
  loguru

log_info "Instalando dependências de desenvolvimento..."

uv add --optional dev \
  ipykernel \
  jupyterlab \
  ruff \
  pytest \
  pytest-cov

# ── Atualizar README.md ────────────────────────────────────────────────────────
log_info "Criando README.md..."
cat > README.md << EOF
# $PROJECT_NAME

> Projeto de Data Science / Machine Learning

## Estrutura do Projeto

\`\`\`
$PROJECT_NAME/
├── data/
│   ├── raw/          # Dados brutos (não modificar)
│   ├── processed/    # Dados processados e limpos
│   ├── interim/      # Dados em transformação intermediária
│   └── external/     # Dados de fontes externas
├── notebooks/
│   ├── exploratory/  # EDA e experimentos
│   ├── modeling/     # Desenvolvimento de modelos
│   └── reports/      # Notebooks para relatórios finais
├── src/$PROJECT_NAME/
│   ├── data.py       # Ingestão e processamento de dados
│   ├── features.py   # Engenharia de features
│   ├── models.py     # Definição e treino de modelos
│   ├── evaluate.py   # Métricas e avaliação
│   ├── visualize.py  # Geração de gráficos
│   └── utils.py      # Utilitários gerais
├── models/
│   ├── trained/      # Modelos treinados (.pkl, .pt, etc.)
│   └── checkpoints/  # Checkpoints de treino
├── configs/
│   └── config.yaml   # Hiperparâmetros e configurações
├── tests/            # Testes unitários
├── reports/
│   └── figures/      # Gráficos e visualizações exportadas
├── logs/             # Logs de treino e execução
├── scripts/          # Scripts utilitários avulsos
├── docs/             # Documentação adicional
├── .env.example      # Exemplo de variáveis de ambiente
├── Makefile          # Atalhos de comandos
└── pyproject.toml    # Dependências e configuração do projeto
\`\`\`

## Configuração do Ambiente

\`\`\`bash
# Instalar dependências
uv sync

# Instalar com dependências de desenvolvimento
uv sync --all-extras

# Ativar o ambiente virtual
source .venv/bin/activate
\`\`\`

## Comandos Úteis

| Comando          | Descrição                     |
|------------------|-------------------------------|
| \`make install\`   | Instala as dependências       |
| \`make test\`      | Roda os testes                |
| \`make lint\`      | Verifica o código com Ruff    |
| \`make format\`    | Formata o código com Ruff     |
| \`make jupyter\`   | Inicia o JupyterLab           |
| \`make clean\`     | Remove arquivos temporários   |

## Adicionar Novas Dependências

\`\`\`bash
uv add <pacote>                  # Dependência de produção
uv add --optional dev <pacote>  # Dependência de desenvolvimento
\`\`\`
EOF

# ── Inicializar git e fazer primeiro commit ────────────────────────────────────
log_info "Inicializando repositório Git..."

git add -A
git commit -m "feat: inicializa estrutura do projeto $PROJECT_NAME com UV

- Estrutura de diretórios para DS/ML
- Dependências principais: pandas, numpy, scikit-learn, matplotlib, seaborn, plotly
- Dependências de dev: jupyterlab, ruff, pytest
- Configurações: pyproject.toml, configs/config.yaml, Makefile
- Notebook exploratório inicial"

# ── Resumo final ───────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  Projeto '$PROJECT_NAME' criado com sucesso!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📁  Diretório : ${BLUE}$(pwd)${NC}"
echo -e "  🐍  Python    : ${BLUE}$PYTHON_VERSION${NC}"
echo -e "  📦  Gerenciador: ${BLUE}UV${NC}"
echo ""
echo -e "  ${YELLOW}Próximos passos:${NC}"
echo -e "  1. ${GREEN}cd $PROJECT_NAME${NC}"
echo -e "  2. ${GREEN}cp .env.example .env${NC}  → configure suas variáveis"
echo -e "  3. ${GREEN}uv sync${NC}               → instala as dependências"
echo -e "  4. ${GREEN}make jupyter${NC}           → abre o JupyterLab"
echo ""

```

## **O que o script faz**

O script cobre todo o ciclo desde a inicialização até o primeiro commit:

**Verificações iniciais**

- Detecta se UV está instalado e, se não estiver, instala automaticamente
- Valida o nome do projeto e evita sobrescrever pastas existentes

**Estrutura de pastas criada**

- `data/` com subpastas `raw`, `processed`, `interim` e `external`
- `notebooks/` dividido em `exploratory`, `modeling` e `reports`
- `src/<projeto>/` com módulos separados: `data.py`, `features.py`, `models.py`, `evaluate.py`, `visualize.py`, `utils.py`
- `models/`, `configs/`, `tests/`, `reports/figures/`, `logs/`, `scripts/`, `docs/`

**Arquivos gerados**

- `pyproject.toml` configurado com dependências de DS/ML via `uv add`
- `configs/config.yaml` com hiperparâmetros, caminhos e seed padrão
- `.gitignore` completo para Python, UV, Jupyter, dados e modelos
- `.env.example` para gerenciamento de segredos
- `Makefile` com atalhos para `install`, `test`, `lint`, `format` e `jupyter`
- Notebook exploratório inicial em `notebooks/exploratory/`
- `README.md` completo com a estrutura documentada

**Dependências instaladas automaticamente**

- Produção: `pandas`, `numpy`, `scikit-learn`, `matplotlib`, `seaborn`, `plotly`, `pyyaml`, `python-dotenv`, `tqdm`, `loguru`
- Dev: `jupyterlab`, `ruff`, `pytest`, `pytest-cov`

## Script ENV DS / FastAPI / Docker

```bash
#!/usr/bin/env bash
# ==============================================================================
# init-project.sh — Cria estrutura completa DS + API para projetos MLOps
#
# Uso:
#   bash init-project.sh <nome-projeto> [diretório-destino] [python-version]
#
# Exemplos:
#   bash init-project.sh fraud-detector
#   bash init-project.sh fraud-detector ~/projetos
#   bash init-project.sh fraud-detector ~/projetos 3.12
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_step()    { echo -e "\n${YELLOW}══ $1${NC}"; }

# ── Argumentos ────────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Uso: $0 <nome-projeto> [diretório-destino] [python-version]"
  exit 1
fi

PROJECT_NAME="$1"
TARGET_DIR="${2:-$PWD}"
PYTHON_VERSION="${3:-3.11}"

if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Nome inválido. Use apenas letras, números, hífens e underscores."; exit 1
fi

TARGET_DIR="$(realpath "$TARGET_DIR")"
mkdir -p "$TARGET_DIR"

DS_DIR="$TARGET_DIR/${PROJECT_NAME}-ds"
API_DIR="$TARGET_DIR/${PROJECT_NAME}-api"
PKG_NAME="${PROJECT_NAME//-/_}"

[ -d "$DS_DIR" ]  && echo "Diretório '$DS_DIR' já existe."  && exit 1
[ -d "$API_DIR" ] && echo "Diretório '$API_DIR' já existe." && exit 1

# ── Verificar UV ──────────────────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
  log_info "Instalando UV..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# ==============================================================================
# PARTE 1 — REPO DE DATA SCIENCE
# ==============================================================================
log_step "Criando repo de Data Science: $DS_DIR"

uv init "$DS_DIR" --python "$PYTHON_VERSION" --no-workspace
cd "$DS_DIR"
rm -f hello.py

# ── Estrutura de pastas ───────────────────────────────────────────────────────
mkdir -p \
  data/{raw,processed,interim,external} \
  notebooks/{exploratory,modeling,reports} \
  src/"$PKG_NAME" \
  models/{trained,checkpoints} \
  configs \
  tests \
  reports/figures \
  scripts \
  logs \
  docs

# ── Módulos do pacote src/ ────────────────────────────────────────────────────
touch src/"$PKG_NAME"/__init__.py
for module in data features train evaluate visualize utils; do
  touch src/"$PKG_NAME"/${module}.py
done
touch tests/__init__.py tests/test_data.py tests/test_train.py

# ── .gitkeeps ─────────────────────────────────────────────────────────────────
for d in data/raw data/processed data/interim data/external \
          models/trained models/checkpoints reports/figures logs; do
  touch "$d/.gitkeep"
done

# ── configs/config.yaml ───────────────────────────────────────────────────────
cat > configs/config.yaml << EOF
project:
  name: ${PROJECT_NAME}
  version: "0.1.0"

data:
  raw_dir: data/raw
  processed_dir: data/processed
  interim_dir: data/interim
  external_dir: data/external

model:
  random_seed: 42
  test_size: 0.2
  validation_size: 0.1
  max_depth: 5

training:
  epochs: 100
  batch_size: 32
  learning_rate: 0.001
  early_stopping_patience: 10

mlflow:
  tracking_uri: "http://localhost:5000"
  experiment_name: "${PROJECT_NAME}"
  registered_model_name: "${PKG_NAME}_model"
EOF

# ── src/train.py ──────────────────────────────────────────────────────────────
cat > src/"$PKG_NAME"/train.py << 'PYEOF'
import mlflow
import mlflow.sklearn
import yaml
import joblib
from pathlib import Path
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import f1_score, accuracy_score
import pandas as pd

def load_config(path: str = "configs/config.yaml") -> dict:
    with open(path) as f:
        return yaml.safe_load(f)

def train(config_path: str = "configs/config.yaml"):
    cfg = load_config(config_path)
    mlflow.set_tracking_uri(cfg["mlflow"]["tracking_uri"])
    mlflow.set_experiment(cfg["mlflow"]["experiment_name"])

    # --- Substitua pelo carregamento real dos seus dados ---
    # df = pd.read_csv("data/processed/dataset.csv")
    # X, y = df.drop("target", axis=1), df["target"]
    # X_train, X_test, y_train, y_test = train_test_split(
    #     X, y,
    #     test_size=cfg["model"]["test_size"],
    #     random_state=cfg["model"]["random_seed"],
    # )

    with mlflow.start_run():
        params = {
            "n_estimators": 100,
            "max_depth": cfg["model"]["max_depth"],
            "random_state": cfg["model"]["random_seed"],
        }
        mlflow.log_params(params)
        mlflow.log_param("test_size", cfg["model"]["test_size"])

        model = RandomForestClassifier(**params)
        # model.fit(X_train, y_train)
        # preds = model.predict(X_test)
        # f1  = f1_score(y_test, preds, average="weighted")
        # acc = accuracy_score(y_test, preds)
        # mlflow.log_metric("f1_score", f1)
        # mlflow.log_metric("accuracy", acc)

        mlflow.sklearn.log_model(
            model,
            artifact_path="model",
            registered_model_name=cfg["mlflow"]["registered_model_name"],
        )

        Path("models/trained").mkdir(exist_ok=True)
        joblib.dump(model, "models/trained/model.pkl")
        mlflow.log_artifact("models/trained/model.pkl")

    print("Treino concluído e modelo registrado no MLflow.")

if __name__ == "__main__":
    train()
PYEOF

# ── src/data.py ───────────────────────────────────────────────────────────────
cat > src/"$PKG_NAME"/data.py << 'PYEOF'
import pandas as pd
from pathlib import Path

def load_raw(filename: str, data_dir: str = "data/raw") -> pd.DataFrame:
    """Carrega dados brutos do disco."""
    path = Path(data_dir) / filename
    return pd.read_csv(path)

def save_processed(df: pd.DataFrame, filename: str, data_dir: str = "data/processed"):
    """Salva dados processados no disco."""
    Path(data_dir).mkdir(parents=True, exist_ok=True)
    df.to_csv(Path(data_dir) / filename, index=False)
    print(f"Dados salvos em {data_dir}/{filename}")
PYEOF

# ── src/features.py ───────────────────────────────────────────────────────────
cat > src/"$PKG_NAME"/features.py << 'PYEOF'
import pandas as pd
from sklearn.preprocessing import StandardScaler

def build_features(df: pd.DataFrame) -> pd.DataFrame:
    """Aplica transformações e engenharia de features."""
    df = df.copy()
    # Exemplo: normalizar colunas numéricas
    # num_cols = df.select_dtypes(include="number").columns
    # scaler = StandardScaler()
    # df[num_cols] = scaler.fit_transform(df[num_cols])
    return df
PYEOF

# ── src/evaluate.py ───────────────────────────────────────────────────────────
cat > src/"$PKG_NAME"/evaluate.py << 'PYEOF'
import pandas as pd
from sklearn.metrics import (
    accuracy_score,
    f1_score,
    precision_score,
    recall_score,
    classification_report,
)

def evaluate_model(model, X_test, y_test) -> dict:
    """Retorna dicionário com métricas de avaliação."""
    preds = model.predict(X_test)
    metrics = {
        "accuracy":  accuracy_score(y_test, preds),
        "f1_score":  f1_score(y_test, preds, average="weighted"),
        "precision": precision_score(y_test, preds, average="weighted"),
        "recall":    recall_score(y_test, preds, average="weighted"),
    }
    print(classification_report(y_test, preds))
    return metrics
PYEOF

# ── src/utils.py ──────────────────────────────────────────────────────────────
cat > src/"$PKG_NAME"/utils.py << 'PYEOF'
import yaml
import logging
from pathlib import Path

def load_config(path: str = "configs/config.yaml") -> dict:
    with open(path) as f:
        return yaml.safe_load(f)

def get_logger(name: str, log_dir: str = "logs") -> logging.Logger:
    Path(log_dir).mkdir(exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler(f"{log_dir}/{name}.log"),
        ],
    )
    return logging.getLogger(name)
PYEOF

# ── pyproject.toml ────────────────────────────────────────────────────────────
cat > pyproject.toml << EOF
[project]
name = "${PROJECT_NAME}-ds"
version = "0.1.0"
description = "Data Science / ML — ${PROJECT_NAME}"
readme = "README.md"
requires-python = ">=${PYTHON_VERSION}"
dependencies = []

[project.optional-dependencies]
dev = ["jupyterlab", "ruff", "pytest", "pytest-cov", "ipykernel"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/${PKG_NAME}"]

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
EOF

# ── .gitignore ────────────────────────────────────────────────────────────────
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
.venv/
*.egg-info/
dist/
build/

# Jupyter
.ipynb_checkpoints/

# Dados (versionados pelo DVC)
data/raw/*
data/processed/*
data/interim/*
data/external/*
!data/**/.gitkeep

# Modelos treinados
models/trained/*
models/checkpoints/*
!models/**/.gitkeep

# Logs e relatórios
logs/*.log
reports/figures/*
!reports/figures/.gitkeep

# MLflow
mlruns/

# DVC
.dvc/tmp
.dvc/cache

# Segredos
.env
.env.*
!.env.example
EOF

# ── .env.example ──────────────────────────────────────────────────────────────
cat > .env.example << EOF
MLFLOW_TRACKING_URI=http://localhost:5000
MLFLOW_EXPERIMENT_NAME=${PROJECT_NAME}
EOF

# ── Makefile ──────────────────────────────────────────────────────────────────
cat > Makefile << EOF
.PHONY: install train test lint format jupyter mlflow-ui dvc-push dvc-pull dvc-repro clean

install:
	uv sync --all-extras

train:
	uv run python -m src.${PKG_NAME}.train

test:
	uv run pytest tests/ -v --cov=src --cov-report=term-missing

lint:
	uv run ruff check src/ tests/

format:
	uv run ruff format src/ tests/

jupyter:
	uv run jupyter lab notebooks/

mlflow-ui:
	uv run mlflow ui --port 5000

dvc-push:
	uv run dvc push

dvc-pull:
	uv run dvc pull

dvc-repro:
	uv run dvc repro

clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".ipynb_checkpoints" -exec rm -rf {} +
EOF

# ── Notebook exploratório ─────────────────────────────────────────────────────
cat > notebooks/exploratory/01_data_exploration.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": ["# Exploração de Dados\n", "\nNotebook inicial para análise exploratória (EDA)."]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "sns.set_theme(style='whitegrid')\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Carregue seus dados aqui\n",
    "# df = pd.read_csv('../../data/raw/dataset.csv')\n",
    "# df.head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# df.info()\n",
    "# df.describe()\n",
    "# df.isnull().sum()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
  "language_info": {"name": "python", "version": "3.11.0"}
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# ── README.md ─────────────────────────────────────────────────────────────────
cat > README.md << EOF
# ${PROJECT_NAME} — Data Science

Repositório de experimentação, treinamento e versionamento de dados do projeto **${PROJECT_NAME}**.
O modelo treinado é publicado no MLflow Model Registry e consumido pelo repo \`${PROJECT_NAME}-api\`.

---

## Pré-requisitos

- [uv](https://github.com/astral-sh/uv) instalado
- [DVC](https://dvc.org/) (instalado via \`uv add dvc\`)
- Acesso ao MLflow Tracking Server (local ou remoto)

---

## Setup

\`\`\`bash
# 1. Instalar todas as dependências (produção + dev)
uv sync --all-extras

# 2. Configurar variáveis de ambiente
cp .env.example .env
# Edite .env com suas configurações reais

# 3. Configurar remote DVC (escolha um)
uv run dvc remote add -d local_remote /tmp/dvc-storage          # local
uv run dvc remote add -d s3_remote s3://meu-bucket/dvc-data     # AWS S3
uv run dvc remote add -d gcs_remote gs://meu-bucket/dvc-data    # GCS
\`\`\`

---

## Estrutura de Pastas

\`\`\`
${PROJECT_NAME}-ds/
│
├── data/                        # Dados do projeto (NÃO commitados — gerenciados pelo DVC)
│   ├── raw/                     # Dados brutos originais, nunca modificados
│   ├── processed/               # Dados limpos, transformados e prontos para treino
│   ├── interim/                 # Dados em transformações intermediárias
│   └── external/                # Dados de fontes externas (APIs, parceiros, etc.)
│
├── notebooks/                   # Jupyter Notebooks organizados por fase
│   ├── exploratory/             # EDA livre — análise inicial, hipóteses, visualizações
│   │   └── 01_data_exploration.ipynb
│   ├── modeling/                # Experimentos de modelagem, comparação de algoritmos
│   └── reports/                 # Notebooks finais e limpos para apresentação
│
├── src/${PKG_NAME}/             # Pacote Python principal (código reutilizável)
│   ├── __init__.py
│   ├── data.py                  # Funções de ingestão, leitura e salvamento de dados
│   ├── features.py              # Engenharia de features e transformações
│   ├── train.py                 # Pipeline de treino com logging no MLflow
│   ├── evaluate.py              # Cálculo e logging de métricas de avaliação
│   ├── visualize.py             # Geração de gráficos e visualizações exportáveis
│   └── utils.py                 # Utilitários: logger, carregamento de config, etc.
│
├── models/                      # Artefatos de modelo (NÃO commitados no Git)
│   ├── trained/                 # Modelos treinados exportados (.pkl, .pt, .onnx)
│   └── checkpoints/             # Checkpoints intermediários de treino (ex: epochs)
│
├── configs/
│   └── config.yaml              # Hiperparâmetros, caminhos e configurações do projeto
│
├── tests/                       # Testes unitários do pacote src/
│   ├── __init__.py
│   ├── test_data.py             # Testa funções de ingestão e processamento
│   └── test_train.py            # Testa o pipeline de treino
│
├── reports/
│   └── figures/                 # Gráficos e imagens exportadas para relatórios
│
├── scripts/                     # Scripts avulsos de automação e utilitários
├── logs/                        # Logs de execução e treino (gerados em runtime)
├── docs/                        # Documentação adicional do projeto
│
├── dvc.yaml                     # Definição do pipeline reproduzível (stages)
├── dvc.lock                     # Lock file do DVC (commitado no Git)
├── .dvc/config                  # Configuração do remote DVC (commitado no Git)
│
├── .env.example                 # Exemplo de variáveis de ambiente
├── .gitignore
├── Makefile                     # Atalhos de comandos
└── pyproject.toml               # Dependências e configuração do projeto (UV)
\`\`\`

---

## Comandos

| Comando | Descrição |
|---|---|
| \`make install\` | Instala todas as dependências |
| \`make train\` | Executa o pipeline de treino e loga no MLflow |
| \`make mlflow-ui\` | Abre o MLflow UI em \`http://localhost:5000\` |
| \`make jupyter\` | Abre o JupyterLab em \`notebooks/\` |
| \`make dvc-repro\` | Executa o pipeline DVC (só roda o que mudou) |
| \`make dvc-push\` | Envia dados e modelos para o remote DVC |
| \`make dvc-pull\` | Baixa dados e modelos do remote DVC |
| \`make test\` | Roda os testes com cobertura |
| \`make lint\` | Verifica o código com Ruff |
| \`make format\` | Formata o código com Ruff |
| \`make clean\` | Remove arquivos temporários e cache |

---

## Fluxo de Trabalho

\`\`\`
1. Dados brutos em data/raw/  (versionados pelo DVC)
        │
        ▼
2. Limpeza e feature engineering  (src/data.py, src/features.py)
        │
        ▼
3. Treino com logging  (make train → MLflow Experiment)
        │
        ▼
4. Avaliação e comparação  (MLflow UI → http://localhost:5000)
        │
        ▼
5. Promoção do melhor modelo  (MLflow UI → "Production")
        │
        ▼
6. API consome automaticamente  (repo ${PROJECT_NAME}-api)
\`\`\`

---

## Adicionar Dependências

\`\`\`bash
uv add <pacote>                   # dependência de produção
uv add --optional dev <pacote>   # dependência de desenvolvimento
\`\`\`

---

## Integração com a API

Após promover um modelo para **Production** no MLflow UI,
o repo \`${PROJECT_NAME}-api\` irá carregar automaticamente o novo modelo
na próxima inicialização do servidor.
EOF

# ── Instalar dependências DS ──────────────────────────────────────────────────
log_info "Instalando dependências DS..."
uv add \
  pandas numpy scikit-learn matplotlib seaborn plotly \
  pyyaml python-dotenv tqdm loguru joblib mlflow dvc

log_info "Instalando dependências de desenvolvimento DS..."
uv add --optional dev jupyterlab ruff pytest pytest-cov ipykernel

# ── Inicializar DVC ───────────────────────────────────────────────────────────
log_info "Inicializando DVC..."
uv run dvc init

# ── Git commit inicial ────────────────────────────────────────────────────────
git add -A
git commit -m "feat: inicializa projeto DS ${PROJECT_NAME}

- src layout com hatchling configurado (packages = src/${PKG_NAME})
- Dependências: pandas, numpy, scikit-learn, mlflow, dvc
- Módulos: data, features, train, evaluate, visualize, utils
- DVC inicializado
- Configs, Makefile, notebook exploratório, README detalhado"

log_success "Repo DS criado em $DS_DIR"

# ==============================================================================
# PARTE 2 — REPO DE API (FastAPI)
# ==============================================================================
log_step "Criando repo de API: $API_DIR"

cd "$TARGET_DIR"
uv init "$API_DIR" --python "$PYTHON_VERSION" --no-workspace
cd "$API_DIR"
rm -f hello.py

# ── Estrutura de pastas ───────────────────────────────────────────────────────
mkdir -p \
  app/{routers,schemas,services,middleware} \
  tests \
  scripts \
  models

touch models/.gitkeep

# ── __init__.py em todos os subpacotes ───────────────────────────────────────
touch app/__init__.py
touch app/routers/__init__.py
touch app/schemas/__init__.py
touch app/services/__init__.py
touch app/middleware/__init__.py
touch tests/__init__.py

# ── app/main.py ───────────────────────────────────────────────────────────────
cat > app/main.py << 'PYEOF'
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.routers import predict
from app.services.model import ModelService

model_service = ModelService()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Carrega o modelo na inicialização e libera recursos no shutdown."""
    model_service.load()
    yield
    model_service.unload()

app = FastAPI(
    title="ML Model API",
    description="API de inferência para modelos de ML",
    version="0.1.0",
    lifespan=lifespan,
)

app.include_router(predict.router, prefix="/api/v1")

@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "model_loaded": model_service.is_loaded}
PYEOF

# ── app/services/model.py ─────────────────────────────────────────────────────
# Parte 1 (EOF): injeta DEFAULT_MODEL_NAME com $PKG_NAME expandido pelo bash
cat > app/services/model.py << EOF
import os
import joblib
import mlflow.pyfunc
from pathlib import Path

DEFAULT_MODEL_NAME = "${PKG_NAME}_model"
EOF

# Parte 2 ('PYEOF'): código Python puro, sem expansão bash
cat >> app/services/model.py << 'PYEOF'

class ModelService:
    def __init__(self):
        self.model = None

    @property
    def is_loaded(self) -> bool:
        return self.model is not None

    def load(self):
        tracking_uri = os.getenv("MLFLOW_TRACKING_URI")
        model_name   = os.getenv("MLFLOW_MODEL_NAME", DEFAULT_MODEL_NAME)
        model_stage  = os.getenv("MLFLOW_MODEL_STAGE", "Production")

        if tracking_uri:
            # Produção: carrega do MLflow Model Registry
            mlflow.set_tracking_uri(tracking_uri)
            self.model = mlflow.pyfunc.load_model(
                f"models:/{model_name}/{model_stage}"
            )
            print(f"Modelo '{model_name}/{model_stage}' carregado do MLflow.")
        else:
            # Desenvolvimento: fallback para modelo local
            local_path = Path(os.getenv("LOCAL_MODEL_PATH", "models/model.pkl"))
            if local_path.exists():
                self.model = joblib.load(local_path)
                print(f"Modelo carregado localmente de '{local_path}'.")
            else:
                print(
                    "[WARN] Nenhum modelo encontrado. "
                    "Configure MLFLOW_TRACKING_URI ou LOCAL_MODEL_PATH."
                )

    def unload(self):
        self.model = None

    def predict(self, features: list[float]):
        if not self.is_loaded:
            raise RuntimeError("Modelo não está carregado.")
        import pandas as pd
        df = pd.DataFrame([features])
        return self.model.predict(df).tolist()[0]
PYEOF

# ── app/schemas/predict.py ────────────────────────────────────────────────────
cat > app/schemas/predict.py << 'PYEOF'
from pydantic import BaseModel, Field
from typing import Any

class PredictRequest(BaseModel):
    features: list[float] = Field(..., description="Vetor de features de entrada")

    model_config = {
        "json_schema_extra": {"example": {"features": [1.2, 3.4, 5.6]}}
    }

class PredictResponse(BaseModel):
    prediction: Any
    probability: float | None = None
    model_version: str = "unknown"
PYEOF

# ── app/routers/predict.py ────────────────────────────────────────────────────
cat > app/routers/predict.py << 'PYEOF'
from fastapi import APIRouter, HTTPException
from app.schemas.predict import PredictRequest, PredictResponse
from app.services.model import ModelService

router = APIRouter(tags=["Inference"])
_svc = ModelService()

@router.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    try:
        result = _svc.predict(req.features)
        return PredictResponse(prediction=result)
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
PYEOF

# ── tests/ ────────────────────────────────────────────────────────────────────
cat > tests/test_health.py << 'PYEOF'
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_returns_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_health_has_model_loaded_field():
    response = client.get("/health")
    assert "model_loaded" in response.json()
PYEOF

cat > tests/test_predict.py << 'PYEOF'
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_predict_without_model_returns_503():
    response = client.post(
        "/api/v1/predict",
        json={"features": [1.0, 2.0, 3.0]},
    )
    assert response.status_code == 503

def test_predict_payload_validation():
    # Features deve ser lista de floats
    response = client.post(
        "/api/v1/predict",
        json={"features": "invalido"},
    )
    assert response.status_code == 422
PYEOF

# ── pyproject.toml ────────────────────────────────────────────────────────────
cat > pyproject.toml << EOF
[project]
name = "${PROJECT_NAME}-api"
version = "0.1.0"
description = "API FastAPI para serving — ${PROJECT_NAME}"
readme = "README.md"
requires-python = ">=${PYTHON_VERSION}"
dependencies = []

[project.optional-dependencies]
dev = ["pytest", "httpx", "ruff"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["app"]

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
EOF

# ── .env.example ──────────────────────────────────────────────────────────────
cat > .env.example << EOF
# Produção: carrega do MLflow Model Registry
MLFLOW_TRACKING_URI=http://mlflow:5000
MLFLOW_MODEL_NAME=${PKG_NAME}_model
MLFLOW_MODEL_STAGE=Production

# Desenvolvimento: usa modelo local (.pkl)
# LOCAL_MODEL_PATH=models/model.pkl
EOF

# ── .gitignore ────────────────────────────────────────────────────────────────
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*.pyo
.venv/
*.egg-info/
dist/
build/

# Modelos (não versionar no Git — usar DVC ou MLflow)
models/*.pkl
models/*.pt
models/*.onnx
!models/.gitkeep

# Segredos
.env
.env.*
!.env.example
EOF

# ── Dockerfile ────────────────────────────────────────────────────────────────
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Copia o binário do UV da imagem oficial
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Instala dependências (aproveita cache do Docker em rebuilds)
COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen --no-dev

# Copia o código da aplicação
COPY app/ ./app/

EXPOSE 8000
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# ── docker-compose.yml ────────────────────────────────────────────────────────
cat > docker-compose.yml << EOF
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - MLFLOW_TRACKING_URI=http://mlflow:5000
      - MLFLOW_MODEL_NAME=${PKG_NAME}_model
      - MLFLOW_MODEL_STAGE=Production
    depends_on:
      - mlflow
    restart: unless-stopped

  mlflow:
    image: ghcr.io/mlflow/mlflow:latest
    ports:
      - "5000:5000"
    command: mlflow server --host 0.0.0.0 --port 5000
    volumes:
      - mlflow_data:/mlflow
    restart: unless-stopped

volumes:
  mlflow_data:
EOF

# ── Makefile ──────────────────────────────────────────────────────────────────
cat > Makefile << 'EOF'
.PHONY: install dev test lint format build up down logs

install:
	uv sync --all-extras

dev:
	uv run uvicorn app.main:app --reload --port 8000

test:
	uv run pytest tests/ -v

lint:
	uv run ruff check app/ tests/

format:
	uv run ruff format app/ tests/

build:
	docker build -t $(shell basename $(CURDIR)):latest .

up:
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f api
EOF

# ── README.md ─────────────────────────────────────────────────────────────────
cat > README.md << EOF
# ${PROJECT_NAME} — API

API FastAPI para servir o modelo treinado no repo \`${PROJECT_NAME}-ds\`.
O modelo é carregado automaticamente do **MLflow Model Registry** na inicialização.

---

## Pré-requisitos

- [uv](https://github.com/astral-sh/uv) instalado
- Docker e Docker Compose (para deploy completo)
- MLflow Tracking Server rodando (ou modelo local em \`models/\`)

---

## Setup

\`\`\`bash
# 1. Instalar dependências
uv sync

# 2. Configurar variáveis de ambiente
cp .env.example .env
# Edite .env com suas configurações

# Opção A — servidor local com modelo do MLflow
make dev

# Opção B — Docker Compose (API + MLflow juntos)
make up
\`\`\`

---

## Estrutura de Pastas

\`\`\`
${PROJECT_NAME}-api/
│
├── app/                         # Pacote principal da aplicação FastAPI
│   ├── __init__.py
│   ├── main.py                  # Entrypoint: cria o app, registra routers, lifespan
│   │
│   ├── routers/                 # Rotas organizadas por domínio
│   │   ├── __init__.py
│   │   └── predict.py           # POST /api/v1/predict — endpoint de inferência
│   │
│   ├── schemas/                 # Modelos Pydantic de request/response
│   │   ├── __init__.py
│   │   └── predict.py           # PredictRequest, PredictResponse
│   │
│   ├── services/                # Lógica de negócio desacoplada dos routers
│   │   ├── __init__.py
│   │   └── model.py             # ModelService: carrega e executa o modelo
│   │
│   └── middleware/              # Middlewares customizados (auth, logging, CORS, etc.)
│       └── __init__.py
│
├── tests/                       # Testes automatizados com TestClient do FastAPI
│   ├── __init__.py
│   ├── test_health.py           # Testa GET /health
│   └── test_predict.py          # Testa POST /api/v1/predict (com e sem modelo)
│
├── models/                      # Modelo local para desenvolvimento sem MLflow
│   └── model.pkl                # Copiado do repo DS ou baixado via DVC
│
├── scripts/                     # Scripts auxiliares (ex: smoke test, warmup)
│
├── Dockerfile                   # Imagem de produção com UV
├── docker-compose.yml           # Orquestra API + MLflow localmente
│
├── .env.example                 # Variáveis de ambiente necessárias
├── .gitignore
├── Makefile                     # Atalhos de comandos
└── pyproject.toml               # Dependências e configuração (UV + Hatchling)
\`\`\`

---

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| \`GET\` | \`/health\` | Status da API e se o modelo está carregado |
| \`POST\` | \`/api/v1/predict\` | Recebe features e retorna predição |
| \`GET\` | \`/docs\` | Swagger UI interativo |
| \`GET\` | \`/redoc\` | Documentação ReDoc |

### Exemplo de chamada

\`\`\`bash
curl -X POST http://localhost:8000/api/v1/predict \\
     -H "Content-Type: application/json" \\
     -d '{"features": [1.2, 3.4, 5.6]}'
\`\`\`

### Resposta esperada

\`\`\`json
{
  "prediction": 1,
  "probability": 0.87,
  "model_version": "unknown"
}
\`\`\`

---

## Comandos

| Comando | Descrição |
|---|---|
| \`make dev\` | Servidor local com hot-reload (porta 8000) |
| \`make test\` | Roda os testes |
| \`make lint\` | Verifica o código com Ruff |
| \`make format\` | Formata o código com Ruff |
| \`make up\` | Sobe API + MLflow com Docker Compose |
| \`make down\` | Para os containers |
| \`make build\` | Build da imagem Docker |
| \`make logs\` | Exibe logs do container da API |

---

## Carregamento do Modelo

O \`ModelService\` segue esta lógica na inicialização:

\`\`\`
MLFLOW_TRACKING_URI definido?
    ├── SIM → carrega models:/<MLFLOW_MODEL_NAME>/<MLFLOW_MODEL_STAGE> do Registry
    └── NÃO → carrega arquivo local em LOCAL_MODEL_PATH (padrão: models/model.pkl)
\`\`\`

Para desenvolvimento sem MLflow, exporte o modelo no repo DS e copie para \`models/\`:

\`\`\`bash
# No repo DS
cp models/trained/model.pkl ../$(echo ${PROJECT_NAME})-api/models/model.pkl
\`\`\`

---

## Integração com DS

O fluxo de integração entre os dois repos é:

\`\`\`
[DS] make train
      └── loga experimento no MLflow
            └── registra modelo em "Staging"
                  └── [aprovação manual no MLflow UI]
                        └── modelo promovido para "Production"
                              └── [API reinicia]
                                    └── ModelService.load() puxa "Production" automaticamente
\`\`\`

---

## Adicionar Dependências

\`\`\`bash
uv add <pacote>                   # dependência de produção
uv add --optional dev <pacote>   # dependência de desenvolvimento
\`\`\`
EOF

# ── Instalar dependências API ─────────────────────────────────────────────────
log_info "Instalando dependências API..."
uv add fastapi "uvicorn[standard]" pydantic mlflow joblib numpy pandas python-dotenv

log_info "Instalando dependências de desenvolvimento API..."
uv add --optional dev pytest httpx ruff

# ── Git commit inicial ────────────────────────────────────────────────────────
# Commita APÓS o uv add para incluir pyproject.toml e uv.lock atualizados
git add -A
git commit -m "feat: inicializa API FastAPI para ${PROJECT_NAME}

- FastAPI com lifespan para carregamento de modelo
- ModelService com suporte a MLflow Registry e fallback local
- Schemas Pydantic: PredictRequest, PredictResponse
- Dockerfile + docker-compose com MLflow
- Testes de health, predict e validação de payload
- hatchling configurado para pacote app/
- README detalhado com estrutura e fluxo de integração"

log_success "Repo API criado em $API_DIR"

# ==============================================================================
# RESUMO FINAL
# ==============================================================================
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  Projeto '${PROJECT_NAME}' criado com sucesso!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📁  DS  → ${BLUE}${DS_DIR}${NC}"
echo -e "  📁  API → ${BLUE}${API_DIR}${NC}"
echo ""
echo -e "  ${YELLOW}Próximos passos:${NC}"
echo ""
echo -e "  ${YELLOW}# 1. Configure o DVC remote no repo DS:${NC}"
echo -e "  cd ${DS_DIR}"
echo -e "  ${GREEN}uv run dvc remote add -d myremote s3://meu-bucket/dvc${NC}"
echo ""
echo -e "  ${YELLOW}# 2. Treine e registre o modelo:${NC}"
echo -e "  ${GREEN}make mlflow-ui${NC}   # em outro terminal → http://localhost:5000"
echo -e "  ${GREEN}make train${NC}"
echo ""
echo -e "  ${YELLOW}# 3. Promova para Production no MLflow UI:${NC}"
echo -e "  ${GREEN}http://localhost:5000${NC}"
echo ""
echo -e "  ${YELLOW}# 4. Suba a API:${NC}"
echo -e "  cd ${API_DIR}"
echo -e "  ${GREEN}make up${NC}    # Docker Compose (API + MLflow)"
echo -e "  ${GREEN}make dev${NC}   # ou servidor local"
echo ""
echo -e "  ${YELLOW}# 5. Teste a API:${NC}"
echo -e "  ${GREEN}curl -X POST http://localhost:8000/api/v1/predict \\${NC}"
echo -e "  ${GREEN}     -H 'Content-Type: application/json' \\${NC}"
echo -e "  ${GREEN}     -d '{\"features\": [1.2, 3.4, 5.6]}'${NC}"
echo ""

```

O script automatiza a criação de um projeto MLOps completo com dois repositórios independentes, cada um com seu próprio ambiente UV, dependências e estrutura de pastas.

---

## O que o script cria

`text[destino]/
├── fraud-detector-ds/    ← experimentação, treino, dados
└── fraud-detector-api/   ← serving em produção com FastAPI`

---

## Repo DS (`-ds`)

Focado no ciclo de **experimentação e treino**. Estrutura principal:

- **`src/<pkg>/`** — pacote Python com módulos separados por responsabilidade: `data.py`, `features.py`, `train.py`, `evaluate.py`, `visualize.py`, `utils.py`
- **`data/`** — 4 camadas (`raw`, `processed`, `interim`, `external`), todas versionadas pelo **DVC**
- **`notebooks/`** — dividido em `exploratory`, `modeling` e `reports`
- **`models/`** — artefatos treinados (`.pkl`, `.pt`), não commitados no Git
- **`configs/config.yaml`** — hiperparâmetros, caminhos e configurações do MLflow
- **Dependências instaladas:** `pandas`, `numpy`, `scikit-learn`, `matplotlib`, `seaborn`, `plotly`, `mlflow`, `dvc`, `loguru`, `joblib`
- **Dev:** `jupyterlab`, `ruff`, `pytest`, `ipykernel`

---

## Repo API (`-api`)

Focado no **serving em produção**. Estrutura principal:

- **`app/`** — pacote FastAPI organizado em `routers/`, `schemas/`, `services/`, `middleware/`
- **`app/services/model.py`** — `ModelService` com lógica dupla: carrega do **MLflow Model Registry** em produção ou de um `.pkl` local em desenvolvimento
- **`app/schemas/predict.py`** — `PredictRequest` e `PredictResponse` com validação Pydantic
- **`Dockerfile`** — imagem slim com UV para builds eficientes
- **`docker-compose.yml`** — orquestra API + MLflow juntos
- **Dependências instaladas:** `fastapi`, `uvicorn`, `pydantic`, `mlflow`, `joblib`, `pandas`, `numpy`
- **Dev:** `pytest`, `httpx`, `ruff`

---

## Tecnologias e decisões de design

| Camada | Ferramenta | Papel |
| --- | --- | --- |
| Gerenciador de pacotes | **UV** | Ambientes virtuais e dependências em ambos os repos |
| Build backend | **Hatchling** | Empacotamento com `src/` layout |
| Versionamento de dados | **DVC** | Rastreia arquivos pesados fora do Git |
| Experiment tracking | **MLflow** | Loga métricas, parâmetros e registra modelos |
| Serving | **FastAPI** | API assíncrona com validação automática |
| Containerização | **Docker Compose** | Sobe API + MLflow com um comando |
| Qualidade de código | **Ruff** | Linting e formatação |

---

## Fluxo completo

`textdados (DVC) → treino (MLflow Experiment)
                    → Model Registry "Production"
                            → API carrega automaticamente
                                    → POST /api/v1/predict`

O **artefato de modelo** é o único ponto de contato entre os dois repos — nunca viaja via Git, sempre pelo MLflow Registry ou via DVC.
