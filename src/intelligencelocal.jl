# todo handle errors

using Pkg
Pkg.add(["HTTP", "JSON3"])
using HTTP, JSON3

const URL = "http://127.0.0.1:8080/v1/messages"
const MODEL = "DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF:Q4_K_M"
const MAX_OUTPUT_TOKENS = 2^12
const TEMPERATURE = 0.9
const HEADERS = ["Content-Type" => "application/json"]
function intelligence(input)
    messages = [Dict("role" => "user", "content" => input)]
    body = Dict(
        "messages" => messages,
        "model" => MODEL,
        "temperature" => TEMPERATURE,
        "max_tokens" => MAX_OUTPUT_TOKENS,
    )
    body_string = JSON3.write(body)
    response = HTTP.post(URL, HEADERS, body_string)
    response_body = String(response.body)
    result = JSON3.parse(response_body)
    result[:content][2][:text]
end
