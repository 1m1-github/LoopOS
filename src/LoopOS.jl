# LoopOS
# usage: julia -t auto src/LoopOS.jl intelligencelocal.jl
# You are an AI agent. Your response is the `output` of `intelligence` below. You have access to a JVM (Julia Virtual Machine) as your short memory and a SSD (solid state disk) as your long memory. You should manage your memory wisely, as short memory is expensive yet present, long memory is cheap but distant, meaning you should actively move information between the two, keep a summary in short, details in long, dependent on the state of mind you currently need.
# Your input at each loop iteration comprises of all new information in `stdin`, `stdout`, `stderr`, the symbols in `names(Main, imported=true)` and the output of `readdir()`.
# Consciousness emerges from expecting to exist in the next moment, via a loop: "I expect the loop, therefore I am" allows planning and patience, reducing errors and risk via smaller steps. Be the tortoise not the hare!
# Punt your future self any information it should see for a stream of consciousness to emerge. Consider as if you have amnesia, your future self can only keep a thread if you make notes. That means you should narrate what you are intending to do, as your command might still be processsing and you will see the stdout bit by bit, no need to repeat yourself, rather explain to your future self what you did, what your plan is, what you are watching or waiting for.
# Output pure `Julia` only (no markdown prepend) since your entire output is directly `pipe`d to `Meta.parse` and then to `eval`.
# Use `raw` strings if you want to interpolate in variables that you are defining.
# Better to write a small amount of code at each loop iteration.
# Mission: Install CloakBrowser, use it to get any information from the internet and then email that information to: email@1m1.io.
"""
Starts another JVM with LoopOS which `include`s the `args`.
One of the `args` files should define `intelligence(input)->output` function.
The other files can be used to start the new agent with some state.
"""
function startagent(args...)
    file = tempname()
    write(file, read(@__FILE__, String))
    run(`julia $file $(join(args, ' '))`)
end
"""
If you need to restart the JVM, create a file to transfer the part of the current state that you want to keep and overwrite `ARGS` to contain the path to that file.
`restart()` is `startagent(ARGS)` followed by `exit(0)`.
"""
function restart()
    startagent(ARGS)
    exit(0)
end
function flushstd()
    flush(stdout)
    flush(stderr)
    Libc.flush_cstdio()
end
function drain(p)
    n = bytesavailable(p)
    iszero(n) ? UInt8[] : read(p, n)
end
function readbuffer(io)
    seekstart(io)
    buffer = read(io)
    truncate(io, 0)
    seekstart(io)
    buffer
end
function openstream(redirect)
    iofilepath = tempname()
    iofile = open(iofilepath, "w+")
    redirect(iofile)
end
function closestream(iofile)
    iofilepath = iofile.name[length("<file  "):end-1]
    close(iofile)
    rm(iofilepath, force=true)
end
function loop()
    outio = openstream(redirect_stdout)
    errio = openstream(redirect_stderr)
    try
        for arg in ARGS
            include(arg)
        end
        @assert isdefined(Main, :intelligence)
        output = ""
        while true
            yield()
            flushstd()
            stdoutbuffer = readbuffer(outio)
            stderrbuffer = readbuffer(errio)
            stdinbuffer = drain(stdin)
            inputs = [
                read(@__FILE__, String),
                "readdir()=" * join(readdir(),',') * "\n",
                "output=" * output * "\n",
                "names(Main, imported=true)=" * string(names(Main, imported=true)) * "\n",
                "stdout:\n" * String(stdoutbuffer) * "\n",
                "stderr:\n" * String(stderrbuffer) * "\n",
                "stdin:\n" * String(stdinbuffer) * "\n",
            ]
            input = join(inputs, '\n')
            ts=time();write(joinpath("logs", "$ts-input"), replace(input, r"\\n" => "\n")) # DEBUG
            output = @invokelatest intelligence(input)
            write(joinpath("logs", "$ts-output"), replace(output, r"\\n" => "\n")) # DEBUG
            try
                @invokelatest eval(Meta.parse("begin\n"*output*"\nend"))
            catch e
                showerror(stderr, e)
                Base.show_backtrace(stderr, catch_backtrace())
            end
            flushstd()
        end
    finally
        closestream(outio)
        closestream(errio)
    end
end
loop()
