
## Install WSL2 no Windows and upgrade ubuntu:

```bash
wsl --install

https://learn.microsoft.com/en-us/windows/wsl/install-manua

#After restart computer:

sudo apt-get update && sudo apt-get upgrade -y
sudo apt install python3-pip

sudo apt-get install tree

```


## Limitar recursos da maquina WSL .wslconfig

```bash
#Criar arquivo .wslconfig na pasta user C:\Users\klysm

[wsl2]
memory=4GB
processors=2
nestedVirtualization=true
```

```bash
sudo reboot
```



## Novo usuário

```bash
#Entrar no modo root
sudo su
#add new user
adduser {name}
#colocar user com privilegio de adm
usermod -a -G sudo {name}
#para logar com o novo user
login {name}
su - name

#defalt user
ubuntu.exe config--default-user name

#add já com sudo su:
sudo useradd -m -G sudo -s /bin/bash nome_do_usuário
#defina a senha em seguida

#alterar senha
sudo passwd nome_do_usuário
```

## ZSH - Oh my ZSH

```bash
#install ZSH
sudo apt install zsh

#install Oh my ZSH
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#alterando o tema
nano .zshrc
ZSH_THEME="fino-time"

#para atualizar
source .zshrc

#plugin autosuggestion
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

#Iniciando plugins em .zshrc
plugins=(git ssh-agent zsh-autosuggestions)
source .zshrc

#Criando um Alias (atalho) em .zshrc (final do arquivo)
alias devkunumi="cd ~/pasta/"

#zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
#add em .zshrc
plugins=( [plugins...] zsh-syntax-highlighting)
source .zshrc

#Install Zinit
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
source .zshrc

#install zplug
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

source ~/.zplug/init.zsh

#install enhanCD power CD manager
zplug "b4b4r07/enhancd", use:init.sh
```

https://github.com/sharkdp/bat

https://github.com/ajeetdsouza/zoxide

## UV - Python ENV

```bash
# On macOS and Linux.
curl -LsSf https://astral.sh/uv/install.sh | sh

# Creat a projec
uv init 

# Create a virtual environment at .venv.
uv venv 

#Activate venv
source .venv/bin/activate

uv pip install flask                # Install Flask.
uv pip install -r requirements.txt  # Install from a requirements.txt file..
uv pip install "package @ ."        # Install the current project from disk
uv pip install "flask[dotenv]"      # Install Flask with "dotenv" extra.

uv pip freeze > requirements.txt # create requeriments

uf add flask.
uv add -r requirements.txt

## to run 
uv run code.py

uv pip compile pyproject.toml -o requirements.txt   # Read a pyproject.toml file.
uv pip compile requirements.in -o requirements.txt  # Read a requirements.in file.
```

## NVM - Node Version Manager

```bash
#install
git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm

#put in zshrc
plugins+=(zsh-nvm)

#install Node LTS

nvm install --lts
nvm use --lts

npm update -g

```

## SSH keygen - Github

```bash

#go homne 
mkdir ~/.ssh
cd ~/.ssh
ssh-keygen -o -t rsa -C "email@example.com" # give a name e pw

# add this key in github
cat github.pub 
*ssh-rsa AAAAB3N....

touch config
nano ~/.ssh/config
##add:
*Host github.com
    Hostname github.com
    User git
    IdentityFile ~/.ssh/githubssh*
```

## Github CC

```bash
git init

git add .

git commit -m "Mensagem descritiva do seu primeiro commit"

#Criar repo no github antes
git remote add origin git@github.com:seu_usuario/nome_do_repositorio.git

git push -u origin main

git status #Exibe o estado dos seus arquivos (se foram modificados, adicionados, etc.).
git log # Mostra o histórico de commits.
git branch #Lista seus branches locais.
git checkout <nome_do_branch> # Muda para um branch específico.

git pull origin main
```

## Docker WSL

[Guia de Instalação do Docker no WSL 2 com Ubuntu 22.04](https://medium.com/@habbema/guia-de-instala%C3%A7%C3%A3o-do-docker-no-wsl-2-com-ubuntu-22-04-9ceabe4d79e8)

```bash
sudo apt update
sudo apt upgrade -y

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker $USER

docker --version
```

## Commands

```bash
#Install
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt install snapd > instalador de pacotes

sudo apt install bat > para leitura de arquivos de forma rapida
sudo apt install tldr > explica determinados comandos
sudo apt install fd-find > encontra arquivos 
sudo apt install ncdu > lista espaço ocupado por pastas e arquivos

#Comandos
man ls > explica os comandos
tldr ls > explica os comandos

curl -I domain.com #requisição

nano text.txt > cria um arquivo novo txt
vim
i #insertmod
ESQ -> normal mode
:q quit
:q! quit without saving
:wq #save and quit

chmod 777 file # dar acesso ao arquivo para todos os users
fdfind klysman > encontra arquivos e pastas
find . -name "*.astro" #encontrar um arquivo 
find . -name "*.astro" | grep index

diff db.conf db.conf2 #verificar dirença entre arquivos

mkdir klysman > cria diretorios
pwd > mostra o atual caminho 

mv arquivo1.txt arquivo2.txt > para renomear arquivos ou movelos
cp para copiar 

head ou tail > mostra as primeiras ou ultimas linhas de um arquivo

rm e rmdir, rm -rf > remove arquivos e remove pastas

hostname > para saber o nome da maquina
free -h > status de recursos 
htop > > status de recursos 
ps aux > lista os processos em execução 

df -h > espaço alocado de memoria storage

history > listar comandos passados

tree > estrutura de pastas 

#Watch
watch -n 1 nvidia-smi #para acompanhar o status de uso da GPU
```

## Lazygit

[GitHub - jesseduffield/lazygit: simple terminal UI for git commands](https://github.com/jesseduffield/lazygit)

## Alias para terminal linux:

Você pode criar aliases para os comandos usados com frequência no terminal Linux para economizar tempo. Por exemplo, se você quiser executar o comando `apt update` como `up`, você pode criar um alias da seguinte forma:

```bash
alias up='apt update'
#Você pode criar alias para qualquer comando usando a seguinte sintaxe:
alias [name_alias]='[command]'

# Alias mais comuns no terminal Linux:
alias l='ls -lh' #lista os arquivos com detalhes
alias ll='ls -alh' #lista todos os arquivos, incluindo ocultos
alias ..='cd ..' #vai para o diretório pai
alias h='history' #mostra o histórico dos comandos executados
alias cls='clear' #limpa o terminal

### Tornar Alias do Terminal Linux Permanentes
#Você pode tornar os alias do terminal linux permanentes, salvando-os no arquivo `~/.bashrc`. Abra o arquivo com seu editor de texto favorito e adicione os alias que deseja salvar. Por exemplo:

alias ls='ls --color=auto --group-directories-first'
alias l='ls --color=auto -lh --group-directories-first'
alias ll='ls --color=auto -lh --group-directories-first'
alias la='ls --color=auto -A --group-directories-first'
alias lla='ls --color=auto -lhA --group-directories-first'
```

## APPS UBUNTU ON WINDOWS

[Ubuntu Desktop/GUI Apps on WSL | Updated Guide](https://youtu.be/7Sym3uL6YWo?t=368)

# Memoria SWAP

O seguinte comando aloca 4Gb de memória SWAP no arquivo swapfile na pasta raiz do sistema.

```bash
sudo swapon --show
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

```bash
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
```

# Extensões

- https://github.com/jarun/nnn/
- https://github.com/Yash-Handa/logo-ls
- https://github.com/amanusk/s-tui
- https://github.com/aristocratos/btop
- https://itsfoss.com/hollywood-hacker-screen/

