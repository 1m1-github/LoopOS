include("intelligencelocalanthropicapi.jl")

intelligence(system, user) = intelligence(
    host="127.0.0.1",
    port=8081,
    system=system,
    user=user,
    # model="DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF:Q4_K_M",
    model="DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF:Q8_0",
    bodyargs=Dict(
        "temperature" => 0.9,
        "max_tokens" => 2^12,
    ),
)

function llamaserver()
    session = "transformer"
    success(`tmux has-session -t $session`) && return
    run(`tmux new-session -d -s $session`)
    cmd = "python3 -m venv llama"
    run(`tmux send-keys -t $session $cmd Enter`)
    cmd = "source llama/bin/activate"
    run(`tmux send-keys -t $session $cmd Enter`)
    # cmd = "pip install -U llama"
    # run(`tmux send-keys -t $session $cmd Enter`)
    # cmd = """llama serve --port 8081 --reasoning-budget 100 -hf "DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF:Q4_K_M\""""
    cmd = """llama serve --port 8081 --reasoning-budget 100 -hf "DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF:Q8_0\""""
    run(`tmux send-keys -t $session $cmd Enter`)
end
llamaserver()
