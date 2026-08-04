include("intelligencelocalopenaiapi.jl")

intelligence(system, user) = intelligence(
    host="127.0.0.1",
    port=8080,
    system=system,
    user=user,
    model="Qwen/Qwen3.6-27B",
    bodyargs=Dict(
        "temperature" => 1.0,
        "max_tokens" => 2^12,
        "chat_template_kwargs" => Dict("enable_thinking" => false)
    ),
)

function mlxserver()
    session = "transformer"
    success(`tmux has-session -t $session`) && return
    run(`tmux new-session -d -s $session`)
    cmd = "python3 -m venv mlx"
    run(`tmux send-keys -t $session $cmd Enter`)
    cmd = "source mlx/bin/activate"
    run(`tmux send-keys -t $session $cmd Enter`)
    cmd = "pip install -U mlx-lm"
    run(`tmux send-keys -t $session $cmd Enter`)
    cmd = "mlx_lm.server --port 8080 --model Qwen/Qwen3.6-27B"
    run(`tmux send-keys -t $session $cmd Enter`)
end
mlxserver()
