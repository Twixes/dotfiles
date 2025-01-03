eval "$(/opt/homebrew/bin/brew shellenv)"
pyenv init - | source
pyenv virtualenv-init - | source
direnv hook fish | source
starship init fish | source

# git aliases

alias g='git'

alias ga='git add'
alias gaa='git add --all'

alias gr='git rebase'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias gri='git rebase --interactive'
alias grm='git rebase master'
alias grim='git rebase --interactive master'
alias grom='git rebase --onto master'

alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gmi='git merge --interactive'
alias gmm='git merge master'
alias gmmi='git merge master --interactive'

alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpf!='git push --force'
