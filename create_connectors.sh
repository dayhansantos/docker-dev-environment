#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

success=false

while [ "$success" = false ]; do
  response=$(curl --silent --fail -X GET http://localhost:8083/connectors)
  
  if [ $? -eq 0 ]; then
    success=true
  else
    echo "Request failed. Retrying in 5 seconds..."
    sleep 5
  fi
done

# Percorre a pasta em busca de arquivos JSON
for arquivo in "$parent_path/kafka-connect/connectors"/*.json; do
    # Verifica se o arquivo existe
    if [ -e "$arquivo" ]; then
        # Obtém o nome do arquivo sem o caminho
        nome_arquivo=$(basename "$arquivo")

        # Executa o comando curl passando o JSON como parâmetro
        http_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d @"$arquivo" http://localhost:8083/connectors)

        # Verifica se o código de status é diferente de 200
        if [ "$http_status" == 201 ]; then
            echo "Connector $nome_arquivo criado com sucesso."
        elif [ "$http_status" == 409 ]; then
            echo "O connector $nome_arquivo já existe."
        else
            echo "Erro ao criar connector $nome_arquivo. Código de status HTTP: $http_status"
        fi
    fi
done