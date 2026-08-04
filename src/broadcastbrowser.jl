include("batchprocessor.jl")

using Pkg
Pkg.add(["HTTP", "URIs", "Sockets"])
using HTTP, URIs, Sockets

struct BroadcastBrowser
    stream::HTTP.Stream
    processor::BatchProcessor{String}
    BroadcastBrowser(stream) = new(stream, BatchProcessor{String}())
end
const BROWSERCLIENTS = Set{BroadcastBrowser}()
Base.put!(::Type{BroadcastBrowser}, js::String) = [put!(client.processor, js) for client = BROWSERCLIENTS]

const HTMLINIT = raw"""
 <!DOCTYPE html>
 <html>
 <body>
 <script>
 window.BASE = window.location.pathname.replace(/\/$/, "")
 window.SSE = new EventSource(`${window.BASE}/events`)
 window.SSE.onmessage = (e) => {console.log(e.data);eval(e.data);}
 </script>
 </body>
 </html>
 """

function safe_write(stream, js)
    try
        write(stream, js)
        flush(stream)
        true
    catch e
        e isa Base.IOError || rethrow()
        false
    end
end

function handle_sse(bb)
    HTTP.setstatus(bb.stream, 200)
    HTTP.setheader(bb.stream, "Content-Type" => "text/event-stream")
    HTTP.setheader(bb.stream, "Cache-Control" => "no-cache")
    HTTP.startwrite(bb.stream)
    start!(bb.processor) do input
        for js = input
            for line = split(js, '\n')
                safe_write(bb.stream, "data: $line\n") || return
            end
            safe_write(bb.stream, "\n") || return
        end
    end
end

anybrowserconnected = false
function awakenbroadcastbrowser(; port, connect, functions)
    @async HTTP.listen!("127.0.0.1", port) do stream
        target = stream.message.target
        uri = URI(target)
        if target == "/"
            HTTP.setstatus(stream, 200)
            HTTP.setheader(stream, "Content-Type" => "text/html")
            HTTP.startwrite(stream)
            write(stream, HTMLINIT)
        elseif uri.path == "/events"
            bb = BroadcastBrowser(stream)
            push!(BROWSERCLIENTS, bb)
            anybrowserconnected = true
            connect(stream)
            handle_sse(bb)
            delete!(BROWSERCLIENTS, bb)
            anybrowserconnected = !isempty(BROWSERCLIENTS)
        elseif haskey(functions, uri.path)
            functions[uri.path](read(stream))
            HTTP.setstatus(stream, 204)
            HTTP.startwrite(stream)
        else
            HTTP.setstatus(stream, 404)
            HTTP.startwrite(stream)
        end
    end
end
