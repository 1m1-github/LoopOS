function browserserver(; path, browserport, sttport)
    session = "browser"
    success(`tmux has-session -t $session`) && return
    run(`tmux new-session -d -s $session`)
    cmd = """julia -L src/runbrowser.jl -e 'runbrowser(path="$path", browserport=$browserport, sttport=$sttport)'"""
    run(`tmux send-keys -t $session $cmd Enter`)
end
