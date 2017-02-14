#!/usr/bin/env bash

# Required

git config --global branch.master.mergeoptions "--no-ff"
git config --global push.default simple
git config --global remote.origin.push HEAD

# Strongly recommended ... but potentially a *massive* pain in the ass if after a lengthy rebase you find someone has made more commits on the remote while you were rebasing:

git config --global branch.master.rebase true
git config --global branch.autosetuprebase always

# Pretty:

git config --global color.diff auto
git config --global color.status auto
git config --global color.branch auto
git config --global color.grep auto
git config --global color.interactive auto
git config --global ui.interactive auto

# Standard aliases:

git config --global alias.co checkout
git config --global alias.a add
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.br branch
git config --global alias.d diff
git config --global alias.m merge

# Serious pimping of git log:

git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(bold yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
