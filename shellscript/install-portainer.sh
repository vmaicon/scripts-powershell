#!/bin/bash

# Escreva aqui as funções

# Lista de dependencias, onde as aplicaões são passadas da maneira a seguir
instalacoes=("docker")

check_dependencias() {
echo "Checando as dependencias necessárias"
echo $instalacoes

for instalacao in "${instalacoes[@]}"
do
    if command -v $instalacao &> /dev/null
    then
        echo "$instalacao está instalado."
    else
        echo "$instalacao não está instalado. Por favor, instale-o antes de prosseguir."
    fi
done
}

# Código aqui, não esqueça de comentar comandos menos conhecidos

check_dependencias

# Crie um arquivo de ajuda, caso o script precise de parametros ou programas auxiliares

# ref https://docs.portainer.io/start/install-ce/server/docker/linux

# cria o volume
docker volume create portainer_data

# sobe a aplicação na porta 9000
docker run -d -p 9000:9000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# install docker standlone
echo "Start portainer agent"

sleep 10s

docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  portainer/agent:2.19.1

# mostara a aplicação rodando
docker ps
