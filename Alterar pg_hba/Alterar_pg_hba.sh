#!/bin/bash

# Limpa a tela do terminal
clear

RESET=`tput sgr0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
CIANO=`tput setaf 6`

# Função para localizar o arquivo pg_hba.conf
encontrar_pg_hba() {
  local pg_hba_path
  pg_hba_path=$(find /etc /var/lib -name "pg_hba.conf" 2>/dev/null)
  echo "$pg_hba_path"
}

# Localizar o arquivo pg_hba.conf
PG_HBA_CONF=$(encontrar_pg_hba)

# Verifica se o arquivo foi encontrado
if [[ -z "$PG_HBA_CONF" ]]; then
  echo -e "${RED}Arquivo pg_hba.conf não encontrado no sistema!${RESET}"
  exit 1
fi

# Exibe a localização do arquivo
echo -e "${GREEN}O arquivo pg_hba.conf está localizado em: $PG_HBA_CONF${RESET}"

# Cabeçalho inicial
echo ""  # Pula uma linha
echo "*********************************************************************************"  # Linha com 80 '*'
echo "*                            ADICIONAR IPs AO PG_HBA                            *"
echo "*********************************************************************************"  # Linha com 80 '*'
echo ""  # Pula uma linha

validar_ip_cidr() {
  local ip="$1"

  # Valida o formato CIDR
  if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+$ ]]; then
    return 1
  fi

  # Extrai o IP e a máscara de rede
  ip_address=$(echo "$ip" | cut -d '/' -f 1)
  # Divide o IP em octetos
  IFS='.' read -r -a octetos <<< "$ip_address"

  # Valida cada octeto
  for octeto in "${octetos[@]}"; do
    if [[ "$octeto" -lt 0 || "$octeto" -gt 255 ]]; then
      return 1
    fi
  done

  # Valida a máscara de rede
  mascara=$(echo "$ip" | cut -d '/' -f 2)
  if [[ "$mascara" -lt 0 || "$mascara" -gt 32 ]]; then
    return 1
  fi

  return 0
}

# Solicita ao usuário para inserir a faixa de IP no formato CIDR
while true; do
  echo -e "${GREEN}Digite a(s) faixa(s) desejada(s):${RESET}"
  echo ""
  echo -e "${YELLOW}Exemplo: 192.168.0.0/24 ou 192.168.0.1/20;192.168.0.2/20 (Para adicionar mais IPs separe por \";\")${RESET}"
  echo ""

  read -p "Digite a(s) faixa(s) desejada(s) no formato CIDR: " ip_range

  # Valida o formato do CIDR
  IFS=';' read -r -a ips <<< "$ip_range"
  erro=false
  for ip in "${ips[@]}"; do
    if ! validar_ip_cidr "$ip"; then
      erro=true
      break
    fi
  done

  # Se houver erro, exibe a mensagem de erro e pede para tentar novamente
  if $erro; then
    echo -e "${RED}Não aceitamos esse formato, digite no formato CIDR conforme passado no exemplo.${RESET}"
  else
    break  # Sai do loop se o formato for válido
  fi
done

# Adiciona a linha de separação após o input
echo ""  # Pula uma linha
echo "*********************************************************************************"  # Linha com 80 '*'
echo ""  # Pula uma linha

# Exibe os IPs digitados, agora em linhas separadas
echo -e "${CIANO}Você digitou os seguintes IPs:${RESET}"
for ip in "${ips[@]}"; do
  echo "$ip"  # Imprime cada IP em uma linha separada
done
echo ""  # Pula uma linha após a listagem dos IPs

# Solicita confirmação, texto em verde
echo ""  # Pula uma linha
echo "*********************************************************************************"  # Linha com 80 '*'
read -p "$(echo -e "${GREEN}Você confirma essas adições? (S/n): ${RESET}")" confirm
echo "*********************************************************************************"  # Linha com 80 '*'

# Verifica a confirmação
if [[ "$confirm" =~ ^[Ss]$ ]]; then
  echo ""  # Pula uma linha
else
  echo -e "${RED}Reinsira os IPs desejados.${RESET}"
  echo ""  # Pula uma linha
  exit 0
fi

# Solicita um único comentário a ser replicado
echo -e "${GREEN}Adicione um comentário para as entradas digitadas (Digite \"n\" para cancelar):${RESET}"
read comment

# Define os espaçamentos fixos entre as colunas
host_spacing="    "       # 4 espaços entre 'host' e o primeiro 'all'
all_spacing="             " # 13 espaços entre o primeiro e o segundo 'all'

# Array para armazenar as entradas adicionadas
added_entries=()

# Divide os IPs por ';' e adiciona cada um no arquivo com o comentário (se aplicável)
for ip in "${ips[@]}"; do
  # Determina o espaçamento dinamicamente com base no comprimento do IP
  if [[ ${#ip} -gt 16 ]]; then
    ip_md5_spacing=$(printf "\t")  # 1 tab para IPs com mais de 16 caracteres
  else
    ip_md5_spacing=$(printf "\t\t")  # 2 tabs para IPs com 16 ou menos caracteres
  fi

  if [[ "$comment" != "n" && -n "$comment" ]]; then
    # Cria a entrada com o comentário
    entry="host${host_spacing}all${all_spacing}all${all_spacing}$ip${ip_md5_spacing}md5 #$comment"
  else
    # Cria a entrada sem comentário
    entry="host${host_spacing}all${all_spacing}all${all_spacing}$ip${ip_md5_spacing}md5"
  fi

  # Adiciona a entrada ao arquivo pg_hba.conf
  printf "%s\n" "$entry" >> "$PG_HBA_CONF"

  # Armazena a entrada no array para exibição posterior
  added_entries+=("$entry")
done

# Exibe as entradas que foram adicionadas ao arquivo, com a linha em verde
echo ""  # Pula uma linha
echo "*********************************************************************************"  # Linha com 80 '*'
echo ""  # Pula uma linha
echo -e "${GREEN}As seguintes entradas foram adicionadas ao arquivo $PG_HBA_CONF:${RESET}"  # Texto em verde
echo ""  # Pula uma linha
for entry in "${added_entries[@]}"; do
  printf "%s\n" "$entry"  # Exibe cada entrada que foi adicionada
done
echo ""  # Pula uma linha
echo "*********************************************************************************"  # Linha com 80 '*' 

# Recarrega o serviço PostgreSQL
sudo systemctl reload postgresql

# Exibe mensagem de sucesso em verde
echo ""  # Pula uma linha antes da mensagem
echo -e "${GREEN}O reload do PostgreSQL foi realizado com sucesso!${RESET}"