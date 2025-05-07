#!/bin/bash

# Arquivo de saída
ARQUIVO_SAIDA="informacoes_sistema.txt"

#Cores
VERDE="\033[0;32m"
RESET="\033[0m"

# Limpa ou cria o arquivo de saída
> "$ARQUIVO_SAIDA"

# Adiciona o cabeçalho inicial
echo "" >> "$ARQUIVO_SAIDA"
echo "*******************************************************************************************" >> "$ARQUIVO_SAIDA"
echo "*                              Dados do Sistema                                           *" >> "$ARQUIVO_SAIDA"
echo "*******************************************************************************************" >> "$ARQUIVO_SAIDA"
echo "" >> "$ARQUIVO_SAIDA"

# Função para adicionar a linha de separação
adicionar_separacao() {
  echo "" >> "$ARQUIVO_SAIDA"
  echo "*******************************************************************************************" >> "$ARQUIVO_SAIDA"
  echo "" >> "$ARQUIVO_SAIDA"
}

# Coleta a memória RAM total
echo "Memória RAM Total:" >> "$ARQUIVO_SAIDA"
echo "" >> "$ARQUIVO_SAIDA"
free -h | awk -v verde="$VERDE" -v reset="$RESET" '/^Mem/ {printf verde "%s" reset "\n", $2}' >> "$ARQUIVO_SAIDA"
adicionar_separacao

# Coleta informações do processador
echo "Processador:" >> "$ARQUIVO_SAIDA"
echo "" >> "$ARQUIVO_SAIDA"
lscpu | grep "Model name" | cut -d: -f2 | sed 's/^ *//g' | head -n 1 | awk -v verde="$VERDE" -v reset="$RESET" '{printf verde "%s" reset "\n", $0}' >> "$ARQUIVO_SAIDA"
adicionar_separacao

# Coleta informações sobre a montagem dos discos
echo "Montagem dos Discos:" >> "$ARQUIVO_SAIDA"
echo "" >> "$ARQUIVO_SAIDA"
df -hT >> "$ARQUIVO_SAIDA"
adicionar_separacao


# Coleta informações do sistema operacional
echo "Sistema Operacional:" >> "$ARQUIVO_SAIDA"
echo "" >> "$ARQUIVO_SAIDA"
cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' | awk -v verde="$VERDE" -v reset="$RESET" '{printf verde "%s" reset "\n", $0}' >> "$ARQUIVO_SAIDA"
adicionar_separacao

# Mensagem final
echo "Informações coletadas e salvas em $ARQUIVO_SAIDA."

cat informacoes_sistema.txt