# todo handle errors

using Pkg
Pkg.add(["HTTP", "JSON3"])
using HTTP, JSON3

function intelligence(;host, port, system, user, model, bodyargs)
    messages = [
        Dict("role" => "system", "content" => system),
        Dict("role" => "user", "content" => user)
    ]
    body = Dict("messages" => messages, "model" => model)
    for (k,v) = bodyargs body[k] = v end
    bodystring = JSON3.write(body)
    response = HTTP.post("http://$host:$port/v1/messages", ["Content-Type" => "application/json"], bodystring)
    response_body = String(response.body)
    result = JSON3.parse(response_body)
    result[:content][2][:text]
end
