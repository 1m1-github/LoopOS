using Pkg
Pkg.add(["HTTP", "JSON3"])
using HTTP, JSON3

function sttserver(;port)
    session = "stt"
    success(`tmux has-session -t $session`) && return
    run(`tmux new-session -d -s $session`)
    cmd = "python3 -m venv parakeet"
    run(`tmux send-keys -t $session $cmd Enter`)
    cmd = "source parakeet/bin/activate"
    run(`tmux send-keys -t $session $cmd Enter`)
    cmd = """pip install "git+https://github.com/huggingface/transformers" fastapi uvicorn python-multipart torch soundfile librosa"""
    run(`tmux send-keys -t $session $cmd Enter`)
    cmd = "uvicorn stt:app --app-dir src --host 0.0.0.0 --port $port --workers 1"
    run(`tmux send-keys -t $session $cmd Enter`)
end
function transcribe(;data, port)
    # serialize(string(time())*"-data", data)
    response = HTTP.post("http://127.0.0.1:$port/pcm", ["Content-Type" => "application/octet-stream"], data)
    json = JSON3.read(response.body)
    json.text
end
