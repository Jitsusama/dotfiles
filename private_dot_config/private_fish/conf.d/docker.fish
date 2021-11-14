if service docker status 2>&1 | grep -q "is not running"
    wsl.exe -d Ubuntu -u root -e /usr/sbin/service docker start >/dev/null 2>&1
end
