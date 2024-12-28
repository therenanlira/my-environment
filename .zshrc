# Set up the shell
export ZSH="$HOME/.oh-my-zsh"

# Set up the theme
ZSH_THEME="devcontainers"

# Set up the plugins
plugins=(git aws virtualenv docker docker-compose zsh-syntax-highlighting zsh-autosuggestions fast-syntax-highlighting)

# Set up the oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Set up the environment
DISABLE_AUTO_UPDATE=true
DISABLE_UPDATE_PROMPT=true

# Update default Shell
export SHELL=/bin/zsh

# Load extras
test -f $HOME/.extras && source $HOME/.extras

# Load Kafka tools
test -f $HOME/.kafka-tools && source $HOME/.kafka-tools
