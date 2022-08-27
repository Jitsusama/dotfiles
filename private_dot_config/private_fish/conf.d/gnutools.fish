for tool_path in (find (brew --prefix)/opt -type d -follow -name gnubin -print)
    fish_add_path $tool_path
end
