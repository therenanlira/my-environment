FROM alpine:3.17
ENV SHELL="/bin/bash"
ENV KUBECONFIG="/home/coder/.kube/config"
ENV PYTHONPATH="/usr/local/lib/python3-*/site-packages"
ENV PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\] \w\[\033[00m\]\\n$ \[\]"

# Create user coder
COPY extras /home/coder/.extras
RUN apk add sudo && \
    adduser -D coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "source .extras" >> /home/coder/.bashrc && \
    chown -R coder: /home/coder/

# Install dependencies
RUN apk add curl wget ed vim bash bash-completion git jq && \
    apk add python3 py3-pip python3-dev && \
    pip3 install --upgrade pip setuptools wheel && \
    pip3 install virtualenv virtualenvwrapper && \
    apk add gcc musl-dev libffi-dev openssl-dev cargo make && \
    pip install --upgrade azure-cli && \
    mkdir $HOME/.virtualenvs && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    apk add kubectx

# Configure user
WORKDIR /home/coder/
USER coder
CMD ["/bin/bash"]