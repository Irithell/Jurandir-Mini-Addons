#!/bin/bash

REPO="Irithell/Jurandir-Mini-Addons"
REMOTE_URL="https://github.com/${REPO}.git"
BRANCH="main"

echo "[ ⚙ ] Gerando hashes dos manifests..."
node scripts/build-hashes.mjs
if [ $? -ne 0 ]; then echo "[ x ] Falha ao gerar hashes."; exit 1; fi

if [ ! -d ".git" ]; then
  echo "[ ⚙ ] Inicializando repositório..."
  git init -b "$BRANCH"
  git remote add origin "$REMOTE_URL"
fi

echo ""
read -p "[ ? ] Mensagem do commit (Enter para 'chore: update'): " MSG
[ -z "$MSG" ] && MSG="chore: update"

git add -A
git commit -m "$MSG"
git push -u origin "$BRANCH"

if [ $? -eq 0 ]; then
  echo "[ ✓ ] Publicado com sucesso!"
else
  echo ""
  read -p "[ ! ] Push falhou. Forçar? [s/N]: " FORCE
  if [[ "$FORCE" =~ ^[sS]$ ]]; then
    git push -u origin "$BRANCH" --force
    [ $? -eq 0 ] && echo "[ ✓ ] Push forçado concluído!" || echo "[ x ] Falha."
  fi
fi
