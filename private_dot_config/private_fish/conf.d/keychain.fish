if test (which keychain)
    status is-interactive; and eval (keychain --agents gpg,ssh --eval 2>/dev/null)
end
