#!/bin/bash

# Lista de dependencias, onde as aplicaões são passadas da maneira a seguir
instalacoes=("curl","google-chrome")

# Adicione aqui a verificação de dependencias necessárias

check_dependencias() {
echo "Checando as dependencias necessárias"

# lista as dependencias necessárias
echo $instalacoes

for instalacao in "${instalacoes[@]}"
do
    if command -v instalacao &> /dev/null
    then
        echo "instalacao está instalado."
    else
        echo "instalacao não está instalado. Por favor, instale-o antes de prosseguir."
    fi
done
}

check_dependencias

#ref. https://www.hostinger.com.br/tutoriais/install-docker-ubuntu

sudo apt update && sudo apt upgrade -y

sudo apt-get install  curl apt-transport-https ca-certificates software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt update

# instala o docker, documentação, compose...
sudo apt install docker docker-compose docker-doc docker.io

# mostra o status do serviço docker
sudo systemctl status docker

# atribui meu usuário atual para o grupo docker, isso me permite executar comandos docker sem o sudo
sudo usermod -aG docker $(whoami)

# abre a documentação para os primeiros passos e para saber mais
export DISPLAY=:0 && google-chrome --new-window 'https://docs.docker.com/get-started/' \
'https://www.hostinger.com.br/tutoriais/install-docker-ubuntu'

echo "Reinicie o sistema para aplicar as politicas"