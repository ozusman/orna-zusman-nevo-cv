#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")"

target="Orna_Zusman_Nevo_CV.pdf"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This updater must be run from inside the CV repository."
  exit 1
fi

if [[ ! -f "$target" ]]; then
  echo "Could not find $target in this folder."
  exit 1
fi

if [[ $# -gt 0 ]]; then
  source_pdf="$1"
else
  source_pdf="$(osascript <<'APPLESCRIPT'
set chosenFile to choose file with prompt "Choose the new CV PDF" of type {"com.adobe.pdf"}
POSIX path of chosenFile
APPLESCRIPT
)"
fi

if [[ ! -f "$source_pdf" ]]; then
  echo "File not found: $source_pdf"
  exit 1
fi

if [[ "${source_pdf:e:l}" != "pdf" ]]; then
  echo "Please choose a PDF file."
  exit 1
fi

if ! head -c 5 "$source_pdf" | grep -q "%PDF-"; then
  echo "This does not look like a valid PDF file."
  exit 1
fi

changed_files="$(git status --porcelain --untracked-files=no | awk '{print $2}')"
if [[ -n "$changed_files" && "$changed_files" != "$target" ]]; then
  echo "There are unrelated local changes. Please commit or stash them first:"
  git status --short
  exit 1
fi

cp "$source_pdf" "$target"

if git diff --quiet -- "$target"; then
  echo "No change detected in $target."
  exit 0
fi

git add "$target"
git commit -m "Update CV PDF"
git push

echo ""
echo "CV PDF updated and pushed."
