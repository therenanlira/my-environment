#!/bin/bash

## Variables
OS=$(uname -s)
DISTRO=$(test -f /etc/os-release && grep "ID_LIKE" /etc/os-release | awk -F= '{ print $2 }')

## Functions
function install_homebrew() {
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
}

## Check if OS is Linux or Darwin
if [ $OS != "Linux" ] && [ $OS != "Darwin" ]; then
  echo "This script is not supported for your OS"
  exit 1
fi

## Identify the shell
test $OS = "Linux" && test $SHELL = "/bin/bash" && RCFILE=$HOME/.bashrc
test $OS = "Darwin" && test $SHELL = "/bin/bash" && RCFILE=$HOME/.bash_profile
test $SHELL = "/bin/zsh" && RCFILE=$HOME/.zshrc

## Update and install basic packages
if [ $OS == "Linux" ]; then
  if [ $DISTRO == "debian" ]; then
    sudo apt update
    INSTALL="sudo apt install -y"
  elif [ $DISTRO == "rhel" ]; then
    sudo dnf update
    INSTALL="sudo dnf install -y"
  fi
elif [ $OS == "Darwin" ]; then
  test ! -f /opt/homebrew/bin/brew && install_homebrew
  INSTALL="brew install"
fi

## Install initial packages
PACKAGES=("neofetch" "figlet" "ed" "jq" "curl" "git" "gawk" "make" "unzip" "vim" "procps" "whois" "nmap")
for package in "${PACKAGES[@]}"; do
  if [ $OS == "Darwin" ]; then
    if ! brew list --formula | grep -q "^$package\$"; then
      $INSTALL $package
    fi
  elif [ $OS == "Linux" ]; then
    if [ $DISTRO == "debian" ]; then
      if ! dpkg -l | grep -q "^ii  $package "; then
        $INSTALL $package
      fi
    elif [ $DISTRO == "rhel" ]; then
      if ! rpm -q $package &>/dev/null; then
        $INSTALL $package
      fi
    fi
  fi
done

## Configure vim
$INSTALL vim
test -f $HOME/.vimrc && rm $HOME/.vimrc
test ! -f $HOME/.vimrc && echo -e 'set ic\nset nu\nset cul\nset cuc\nset bg=dark' >> $HOME/.vimrc

## Install network tools
$INSTALL watch whois nmap

## Configure git
if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
  echo -e "\n\n\n########## Configuring git... ##########\n\n\n"
  read -p "Your name: " name
  read -p "Your GitHub email: " email
  git config --global user.name "$name"
  git config --global user.email "$email"
fi

## Install and configure bash-it or zsh and themes
if [ $SHELL == "/bin/bash" ]; then
  git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it \
  && printf 'y' | ~/.bash_it/install.sh
  git clone --depth=1 https://github.com/therenanlira/bash-it-themes.git ~/.bash-it-themes \
  && printf 'y' | ~/.bash-it-themes/install.sh
  sed -i "" "s/export BASH_IT_THEME=.*/\export BASH_IT_THEME=new-sushu/g" $RCFILE
  source $RCFILE
elif [ $SHELL == "/bin/zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  test ! -f $ZSH_CUSTOM/plugins/fast-syntax-highlighting || git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git $ZSH_CUSTOM/plugins/fast-syntax-highlighting
  test ! -f $ZSH_CUSTOM/plugins/zsh-autosuggestions      || git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
  test ! -f $ZSH_CUSTOM/plugins/zsh-syntax-highlighting  || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

  grep -q "source $ZSH/oh-my-zsh.sh" $RCFILE || echo -e "source $ZSH/oh-my-zsh.sh" >> $RCFILE

  new_plugins=("aws" "git" "zsh-syntax-highlighting" "zsh-autosuggestions" "fast-syntax-highlighting" "virtualenv" "docker" "docker-compose")
  current_plugins=$(grep -oP '(?<=^plugins=\().*(?=\))' $RCFILE)
  for plugin in "${new_plugins[@]}"; do
    if [[ ! " ${current_plugins[@]} " =~ " ${plugin} " ]]; then
      current_plugins+=" ${plugin}"
    fi
  done
  sed -i "s/^plugins=(.*)/plugins=(${current_plugins})/" $RCFILE
fi

## Install programming languages
$INSTALL nodejs npm python3 python3-pip pipx golang

## Install X Code
test $OS = "Darwin" && xcode-select --install

## Install TLDR
if ! tldr --version &>/dev/null; then
  test $OS = "Linux" && sudo npm install -g tldr
  test $OS = "Darwin" && npm install -g tldr
fi

## Install FZF
if ! fzf --version &>/dev/null; then
  if [ $OS == "Linux" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  elif [ $OS == "Darwin" ]; then
    $INSTALL fzf
    $(brew --prefix)/opt/fzf/install
  fi
fi

source $RCFILE
test $SHELL = "/bin/bash" && eval "$(fzf --bash)"
test $SHELL = "/bin/zsh" && source <(fzf --zsh)

## Install TFSwitch (Terraform version manager)
if ! tfswitch --version &>/dev/null; then
  wget https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh
  chmod 755 install.sh
  ./install.sh -b $HOME/.bin
  rm install.sh
fi

## Install TFSec
if [ $OS == "Linux" ]; then
  curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
else
  $INSTALL tfsec
fi

## Install Terraform Docs
if [ $OS == "Linux" ]; then
  curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.18.0/terraform-docs-v0.18.0-$(uname)-amd64.tar.gz
  tar -xzf terraform-docs.tar.gz
  chmod +x terraform-docs
  mv terraform-docs /usr/local/bin/terraform-docs
else
  $INSTALL terraform-docs
fi

## Install AWS CLI
if [ $OS == "Linux" ]; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf awscliv2.zip aws
  curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
  sudo dpkg -i session-manager-plugin.deb
elif [ $OS == "Darwin" ]; then
  curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
  sudo installer -pkg AWSCLIV2.pkg -target /
  rm -rf AWSCLIV2.pkg
  curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/session-manager-plugin.pkg" -o "session-manager-plugin.pkg"
  sudo installer -pkg session-manager-plugin.pkg -target /
  sudo ln -s /usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin
fi

## Install Azure CLI
test $OS = "Linux" && curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
test $OS = "Darwin" && $INSTALL azure-cli

## Install Google Cloud CLI
if [ $OS == "Linux" ]; then
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  sudo apt update
  $INSTALL google-cloud-sdk
elif [ $OS == "Darwin" ]; then
  $INSTALL --cask google-cloud-sdk
fi

## Install Kubernetes tools
if [ $OS == "Linux" ]; then
  $INSTALL apt-transport-https ca-certificates curl gnupg
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
  sudo apt update
  $INSTALL kubectl

  $INSTALL bash-completion
  test $SHELL = "/bin/bash" && $INSTALL bash-completion
  test $SHELL = "/bin/bash" && source <(kubectl completion bash)
  test $SHELL = "/bin/zsh" && source <(kubectl completion zsh)

  sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
  sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
  sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

  sh -c "$(curl -sSL https://git.io/install-kubent)"

  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  rm get_helm.sh

  curl -sS https://webinstall.dev/k9s | bash
elif [ $OS == "Darwin" ]; then
  $INSTALL kubectl
  test $SHELL = "/bin/bash" && $INSTALL bash-completion@2
  test $SHELL = "/bin/bash" && kubectl completion bash > $(brew --prefix)/etc/bash_completion.d/kubectl
  test $SHELL = "/bin/zsh" && source <(kubectl completion zsh) && autoload -Uz compinit && compinit

  $INSTALL kubectx # and kubens
  
  $INSTALL kubent

  $INSTALL helm
  
  $INSTALL k9s
fi

## Install krew
if ! kubectl krew version &>/dev/null; then
  (
    set -x; cd "$(mktemp -d)" &&
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
    KREW="krew-${OS}_${ARCH}" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
    tar zxvf "${KREW}.tar.gz" &&
    ./"${KREW}" install krew
  )
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
fi

## Install kubectl-node-shell
if ! kubectl node-shell --version &>/dev/null; then
  kubectl krew install neat
  curl -LO https://github.com/kvaps/kubectl-node-shell/raw/master/kubectl-node_shell
  sudo chown root:root kubectl-node_shell
  sudo chmod +x kubectl-node_shell
  sudo mv kubectl-node_shell /usr/local/bin/kubectl-node_shell
fi

## Install CMCTL and CFSSL
if [ $OS == "Linux" ]; then
  if cmctl --version &>/dev/null; then
    CMCTL_VERSION=0.5.0
    curl -fsSLO "https://github.com/oleewere/cmctl/releases/download/v${CMCTL_VERSION}/cmctl_${CMCTL_VERSION}_linux_64-bit.tar.gz" && 
    sudo tar zxvf cmctl_${CMCTL_VERSION}_linux_64-bit.tar.gz -C /usr/local/bin cmctl
    rm cmctl_${CMCTL_VERSION}_linux_64-bit.tar.gz
  fi

  if cfssl &>/dev/null; then
    CFSSL_VERSION=1.6.5
    curl -fsSLO "https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/cfssl-bundle_${CFSSL_VERSION}_linux_amd64" &&
    sudo mv cfssl-bundle_${CFSSL_VERSION}_linux_amd64 /usr/local/bin/cfssl
    sudo chown root:root /usr/local/bin/cfssl
    sudo chmod 755 /usr/local/bin/cfssl
  fi
elif [ $OS == "Darwin" ]; then
  brew tap oleewere/repo
  $INSTALL cmctl
  $INSTALL cfssl
fi

## Install e1s
if [ $OS == "Linux" ]; then
  E1S_VERSION="1.0.34"
  E1S_OS="linux_amd64"

  curl -fsSLO https://github.com/keidarcy/e1s/releases/download/v$E1S_VERSION/e1s_$E1S_VERSION\_$E1S_OS.tar.gz
  sudo tar zxvf e1s_$E1S_VERSION\_$E1S_OS.tar.gz -C /usr/local/bin e1s
  sudo chown root:root /usr/local/bin/e1s
  sudo chmod +x /usr/local/bin/e1s
  rm e1s_$E1S_VERSION\_$E1S_OS.tar.gz
elif [ $OS == "Darwin" ]; then
  $INSTALL e1s
fi

## Install Docker
read -p "Install Docker? [y/N] " yn
case $yn in
  [Yy] )
      if [ $OS == "Linux" ]; then
        $INSTALL docker.io
        sudo systemctl enable docker
        sudo systemctl start docker
      elif [ $OS == "Darwin" ]; then
        $INSTALL docker
        $INSTALL --cask docker
      fi;;
  [Nn]* ) ;;
esac

## Install VS Code
read -p "Install Visual Studio Code? [y/N] " yn
case $yn in
  [Yy] )
      if [ $OS == "Linux" ]; then
        $INSTALL code
      elif [ $OS == "Darwin" ]; then
        $INSTALL --cask visual-studio-code
      fi;;
  [Nn]* ) ;;
esac

## Install Postman
read -p "Install Postman? [y/N] " yn
case $yn in
  [Yy] )  $INSTALL postman;;
  [Nn]* ) ;;
esac

## Extras Bash configurations
rm $HOME/.extras &>/dev/null \
&& curl -o $HOME/.extras https://raw.githubusercontent.com/therenanlira/my-environment/main/extras
if ! grep -q "# Load extras" $RCFILE; then
  echo -e "\n# Load extras\ntest -f \$HOME/.extras && source \$HOME/.extras" >> $RCFILE
fi

## Kafka tools configuration
rm $HOME/.kafka-tools &>/dev/null \
&& curl -o $HOME/.kafka-tools https://raw.githubusercontent.com/therenanlira/my-environment/main/kafka-tools
if ! grep -q "# Load Kafka tools" $RCFILE; then
  echo -e "\n# Load Kafka tools\ntest -f \$HOME/.kafka-tools && source \$HOME/.kafka-tools" >> $RCFILE
fi
