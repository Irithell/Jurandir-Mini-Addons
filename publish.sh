#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[1;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[1;30m'

REPO="Irithell/Jurandir-Mini-Addons"
REMOTE_URL="https://github.com/${REPO}.git"
BRANCH="main"

clear
printf "${CYAN}==================================================\n"
printf "   JURANDIR MINI ADDONS — PUBLISH\n"
printf "==================================================${NOCOLOR}\n\n"

if ! command -v git >/dev/null 2>&1; then echo -e "${RED}[ x ] Git não encontrado.${NOCOLOR}"; exit 1; fi
if ! command -v node >/dev/null 2>&1; then echo -e "${RED}[ x ] Node não encontrado.${NOCOLOR}"; exit 1; fi

if [ ! -d ".git" ]; then
  printf "${CYAN}[ ⚙ ] Inicializando repositório...${NOCOLOR}\n"
  git init -b "$BRANCH" >/dev/null 2>&1
  git remote add origin "$REMOTE_URL"
  printf "${GREEN}[ ✓ ] Repositório inicializado.${NOCOLOR}\n\n"
fi

printf "${YELLOW}[ FASE 1 ] GERANDO HASHES DOS MANIFESTS${NOCOLOR}\n"
node scripts/build-hashes.mjs
if [ $? -ne 0 ]; then printf "${RED}[ x ] Falha ao gerar hashes. Abortando.${NOCOLOR}\n"; exit 1; fi

printf "\n${YELLOW}[ FASE 2 ] DIFF — O QUE ESTÁ SENDO ENVIADO${NOCOLOR}\n\n"

ADDED=$(git status --porcelain | grep '^?' | wc -l | tr -d ' ')
MODIFIED=$(git status --porcelain | grep '^.M\|^M' | wc -l | tr -d ' ')
DELETED=$(git status --porcelain | grep '^.D\|^D' | wc -l | tr -d ' ')

git status --porcelain | while read STATUS FILE; do
  case "$STATUS" in
    \?\?) printf "  ${GREEN}[ + ] ${FILE}${NOCOLOR}\n" ;;
    M|MM|\ M) printf "  ${YELLOW}[ ~ ] ${FILE}${NOCOLOR}\n" ;;
    D|\ D) printf "  ${RED}[ - ] ${FILE}${NOCOLOR}\n" ;;
    *) printf "  ${BLUE}[ ${STATUS} ] ${FILE}${NOCOLOR}\n" ;;
  esac
done

TOTAL=$((ADDED + MODIFIED + DELETED))

printf "\n${CYAN}Resumo: ${GREEN}${ADDED} novo(s)${NOCOLOR} · ${YELLOW}${MODIFIED} modificado(s)${NOCOLOR} · ${RED}${DELETED} removido(s)${NOCOLOR}\n"

if [ "$TOTAL" -eq 0 ]; then
  printf "\n${GREEN}[ ✓ ] Nada a publicar. Repositório já está atualizado.${NOCOLOR}\n"
  exit 0
fi

printf "\n${YELLOW}Deseja prosseguir com o commit e push? [S/n]: ${NOCOLOR}"
read CONFIRM
case "$CONFIRM" in
  [nN]) printf "${BLUE}[ i ] Operação cancelada.${NOCOLOR}\n"; exit 0 ;;
esac

printf "\n${YELLOW}Mensagem do commit (Enter para 'chore: update'): ${NOCOLOR}"
read MSG
[ -z "$MSG" ] && MSG="chore: update"

git add -A
git commit -m "$MSG" >/dev/null 2>&1
PUSH_OUTPUT=$(git push -u origin "$BRANCH" 2>&1)

if [ $? -eq 0 ]; then
  printf "${GREEN}[ ✓ ] Publicado com sucesso!${NOCOLOR}\n"
else
  printf "\n${YELLOW}[ ! ] Conflito remoto detectado.\n${PUSH_OUTPUT}\n\n"
  printf "${RED}Deseja forçar o push? [s/N]: ${NOCOLOR}"
  read FORCE
  if [[ "$FORCE" =~ ^[sS]$ ]]; then
    git push -u origin "$BRANCH" --force >/dev/null 2>&1
    [ $? -eq 0 ] && printf "${GREEN}[ ✓ ] Push forçado concluído!${NOCOLOR}\n" || { printf "${RED}[ x ] Falha.${NOCOLOR}\n"; exit 1; }
  else
    printf "${BLUE}[ i ] Push cancelado.${NOCOLOR}\n"
  fi
fi