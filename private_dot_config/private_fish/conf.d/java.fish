if test (which javac)
    set -Ux JAVA_HOME (dirname (dirname (readlink -f (which javac))))
end
