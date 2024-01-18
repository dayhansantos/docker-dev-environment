#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# Lista de opções
options=("Criar ambiente de desenvolvimento" "Criar conectores Kafka" "Criar alias" "Sair")

function create_alias {
    dir=$(pwd)
    aliases=("alias dev='bash $dir/dev.sh'")

    for alias in "${aliases[@]}"
    do
        # Verifica se o usuário está usando Zsh
        if [[ -z "$(grep "$alias" ~/.zshrc)" && "$SHELL" == */zsh ]]; then
            echo $alias >> ~/.zshrc
        # Verifica se o usuário está usando Bash
        elif [[ -z "$(grep "$alias" ~/.bashrc)" &&  "$SHELL" == */bash ]]; then
            echo $alias >> ~/.bashrc
        fi
    done

    printf "\nObs.: Para funcionar o alias, abra um novo terminal ou execute o comando 'source ~/.zshrc' ou 'source ~/.bashrc' dependendo do shell utilizado."
    printf "\n- Para subir o ambiente, rode o comando 'dev start'."
    printf "\n- Para parar o ambiente, rode o comando 'dev stop'."
    printf "\n- Para reiniciar o ambiente, rode o comando 'dev restart'."
    printf "\n- Visualizar os logs, rode o comando 'dev logs {nome-do-container}'."
    printf "\n- Para construir o ambiente novamente do zero, rode o comando 'dev build'."
    printf "\n- Para limpar o ambiente excluindo todos os containers e volumes, rode o comando 'dev drop'."
    printf "\n- Para atualizar o ambiente (atualizar tabelas, connectors, etc.), rode o comando 'dev update'.\n"
}

function build_environment {
    printf "\nCriando imagens docker...\n\n"
    docker-compose -f $parent_path/docker-compose.yaml up --build -d
}

# Loop principal
while true; do
    # Mostra a lista de opções
    printf "\nEscolha uma opção:\n"
    for i in "${!options[@]}"; do
        echo "$((i+1))) ${options[$i]}"
    done

    # Lê a opção escolhida
    read -r selected_option

    # Valida a opção escolhida
    if (( selected_option == ${#options[@]} )); then
        echo "Saindo..."
        exit 0
    elif (( selected_option < 0 || selected_option >= ${#options[@]} )); then
        echo "Opção inválida"
        continue
    fi

    # Executa um comando com base na opção escolhida
    case "$selected_option" in
        "1")
            printf "\n############## Construindo ambiente de desenvolvimento ##############\n"
            build_environment
            ;;
        "2")
            printf "\nCriando conectores kafka... \n"
            bash create_connectors.sh
            ;;
        "3")
            echo "Criando alias para o ambiente de desenvolvimento..."
            create_alias
            ;;
        *)
            echo "Opção inválida"
            continue
            ;;
    esac
done