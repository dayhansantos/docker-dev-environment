#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# Verifica se o argumento foi passado
if [ -z "$1" ]
  then
    echo "Nenhum argumento fornecido"
    exit 1
fi

function drop_environment {
    printf "\nRemovendo containers...\n"
    docker rm -f $(docker ps -a -q)

    printf "\nRemovendo volumes...\n"
    docker volume rm $(docker volume ls -q)

    docker builder prune --all --force
}

function update_environment {
    printf "Atualizando banco de dados\n"

    git -C "$parent_path/liquibase/postgres/changelog/liquibase-repository" pull

    docker-compose up --build liquibase -d
}

# Executa um comando com base no argumento fornecido
case "$1" in
    "compose")
        docker-compose -f $parent_path/docker-compose.yaml $2
    ;;
    "build")
        bash $parent_path/build.sh
    ;;
    "stop")
        docker-compose -f $parent_path/docker-compose.yaml stop $2
    ;;
    "start")
        docker-compose -f $parent_path/docker-compose.yaml start $2
    ;;
    "restart")
        docker-compose -f $parent_path/docker-compose.yaml restart $2
    ;;
    "logs")
        docker-compose -f $parent_path/docker-compose.yaml logs -f $2
    ;;
    "drop")
        echo "Limpando o ambiente de desenvolvimento..."
        drop_environment
    ;;
    "update")
        echo "Atualizando o ambiente de desenvolvimento..."
        update_environment
    ;;
    "connect-update")
        printf "Atualizando conectores kafka...\n"
        bash $parent_path/create_connectors.sh
    ;;
    "help")
        printf "Comandos:
    compose         Acessa os comandos do docker compose padrão. Ex: dev compose up -d
    build           Inicia a criação do ambiente de desenvolvimento
    stop            Interrompe a execução dos containers. Pode ser usado para interromper todos ou algum em específico. Ex: dev stop connect
    start           Inicia a execução dos containers. Pode ser usado para iniciar todos ou algum em específico. Ex: dev start connect
    restart         Reinicia a execução dos containers. Pode ser usado para reiniciar todos ou algum em específico. Ex: dev restart connect
    logs            Visualiza os logs de um container em específico. Ex: dev logs connect
    drop            Exclui todos os containers e volumes para limpar o ambiente. Usado caso queira começar do zero.
    update          Atualiza o ambiente e containers. É usado principalmente para executar o liquibase e atualizar o banco de dados
    connect-update  Atualiza os conectores kafka, criando novos conectores se necessário\n"
    ;;
    *)
        echo "Opcao invalida"
        exit 1
    ;;
esac

exit 0