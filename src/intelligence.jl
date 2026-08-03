# DEBUG
# intelligence(s,u) = begin sleep(5);"println(rand())" end

# MLX
# tmux new -s mlx
# python3 -m venv mlx
# source mlx/bin/activate
# mlx_lm.server --model Qwen/Qwen3.6-27B --port 8080
# include("intelligencelocalopenaiapi.jl")
# intelligence(system, user) = intelligence(
#     host="127.0.0.1",
#     port=8080,
#     system=system,
#     user=user,
#     model="Qwen/Qwen3.6-27B",
#     bodyargs=Dict(
#         "temperature" => 1.0,
#         "max_tokens" => 2^12,
#         "chat_template_kwargs" => Dict("enable_thinking" => false)
#     ),
# )

# llama.cpp
# tmux new -s llama
# python3 -m venv llama
# source llama/bin/activate
# llama serve --port 8080 --reasoning-budget 10 --hf "DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF:Q4_K_M"
# include("intelligencelocalanthropicapi.jl")
# intelligence(system, user) = intelligence(
#     host="127.0.0.1",
#     port=8080,
#     system=system,
#     user=user,
#     model="DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF:Q4_K_M",
#     bodyargs=Dict(
#         "temperature" => 1.0,
#         "max_tokens" => 2^12,
#     ),
# )

# X AI

# Anthropic

# OpenAI
