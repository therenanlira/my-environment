FROM alpine:3.17
ENV SHELL="/bin/bash"
ENV KUBECONFIG="/home/coder/.kube/config"
ENV PYTHONPATH="/usr/local/lib/python3-*/site-packages"
ENV PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\] \w\[\033[00m\]\\n$ \[\]"

# Create user coder
COPY bashrc-extras /home/coder/.bashrc-extras
RUN apk add sudo
RUN adduser -D coder
RUN echo "coder:Docker!" | chpasswd
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "source .bashrc-extras" >> /home/coder/.bashrc
RUN chown -R coder: /home/coder/

# Install dependencies
RUN apk add curl wget ed vim bash bash-completion git jq

# Install python
RUN apk add python3 py3-pip python3-dev
RUN pip3 install --upgrade pip setuptools wheel
RUN pip3 install virtualenv virtualenvwrapper

# Install az cli
RUN apk add gcc musl-dev libffi-dev openssl-dev cargo make
RUN pip install --upgrade azure-cli
RUN mkdir $HOME/.virtualenvs

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN apk add kubectx

# Configure user
WORKDIR /home/coder/
USER coder
CMD ["/bin/bash"]