function browserserver(;path,port)
    session = "browser"
    success(`tmux has-session -t $session`) && return
    run(`tmux new-session -d -s $session`)
    cmd = "julia -L runbrowser.jl -e 'runbrowser(path=$path,port=$port)'"
    run(`tmux send-keys -t $session $cmd Enter`)
end
