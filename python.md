## Environment UV

```bash
pip install uv

# Creat a projec
uv init 

 # Create a virtual environment at .venv.
uv venv 

#Activate venv

# On macOS and Linux.
source .venv/bin/activate

# On Windows.
.venv\Scripts\activate

uv pip install flask                # Install Flask.
uv pip install -r requirements.txt  # Install from a requirements.txt file.
uv pip install -e .                 # Install the current project in editable mode.
uv pip install "package @ ."        # Install the current project from disk
uv pip install "flask[dotenv]"      # Install Flask with "dotenv" extra.

uv pip freeze > requirements.txt # create requeriments

uf add flask...
uv add -r requirements.txt

## to run 
uv run code.py

## clone projetc
uv venv
source .venv/bin/activate
uv pip compile pyproject.toml -o requirements.txt   # Read a pyproject.toml file.
uv pip install -r requirements.txt

uv pip compile requirements.in -o requirements.txt  # Read a requirements.in file.
```

## Code formatter

https://github.com/astral-sh/ruff

```bash
uv pip install ruff
uv add --dev ruff

#in pyproject.toml add
[tool.ruff]
line-length = 79
extend-exclude = ['migrations']

[tool.ruff.lint]
preview = true
select = ['I', 'F', 'E', 'W', 'PL', 'PT']

[tool.ruff.format]
preview = true
quote-style = 'single'

[tool.pytest.ini_options]
pythonpath = "."
addopts = '-p no:warnings'
```

## PIPs

```bash
uv pip install pytest pytest-cov taskipy ruff

uv pip install ignr

uv run ignr -p python > .gitignore
```

## Pyproject.toml

```python
[tool.ruff]
line-length = 79
extend-exclude = ['migrations']

[tool.ruff.lint]
preview = true
select = ['I', 'F', 'E', 'W', 'PL', 'PT']

[tool.ruff.format]
preview = true
quote-style = 'single'

[tool.pytest.ini_options]
pythonpath = "."
addopts = '-p no:warnings'

[tool.taskipy.tasks]
lint = 'ruff check'
pre_format = 'ruff check --fix'
format = 'ruff format'

run = 'fastapi dev src/fast_zero/app.py'

pre_test = 'task lint'
test = 'uv run pytest -s -x --cov=fast_zero -vv'
post_test = 'coverage html'

piplist = 'uv pip freeze > requirements.txt && uv add -r requirements.txt'
```
