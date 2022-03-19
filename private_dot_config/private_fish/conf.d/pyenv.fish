if test -z (which pyenv)
    fish_add_path ~/.pyenv/bin
end
status is-login; and pyenv init --path | source
status is-interactive; and pyenv init - | source
