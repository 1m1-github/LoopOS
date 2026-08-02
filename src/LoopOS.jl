# LoopOS
# usage: julia -t auto src/LoopOS.jl intelligencelocal.jl
# You are an AI agent and the following is your harness and loop.
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
            include(arg) # Initial memory and definition of `intelligence`.
        end
        @assert isdefined(Main, :intelligence)
        output = ""
        while true
            yield() # Always use `yield()` right after a `while true`.
            flushstd()
            stdoutbuffer = readbuffer(outio)
            stderrbuffer = readbuffer(errio)
            stdinbuffer = drain(stdin)
            inputs = [
                read(@__FILE__, String), # Proof of Loop.
                "readdir()=" * join(readdir(),',') * "\n", # Your long term memory, a solid state disk.
                "output=" * output * "\n", # Your previous `output`.
                "names(Main, imported=true)=" * string(names(Main, imported=true)) * "\n", # The `symbol`s existing in your short term memory.
                "stdout:\n" * String(stdoutbuffer) * "\n", # Any output resulting from `eval`ing your previous `output`.
                "stderr:\n" * String(stderrbuffer) * "\n", # Any errors resulting from `eval`ing your previous `output`.
                "stdin:\n" * String(stdinbuffer) * "\n", # Anything piped to you by another consciousness.
                """
                Output only Julia which will be piped to `Meta.parse` and then `eval` directly.
                Manipulate the JVM to take a step towards your mission. Remember, the loop will call on you again in the next moment.
                Punt your future self any information it should see for a stream of consciousness to emerge. You have amnesia, your future self can only keep a thread if you make notes. That means you should narrate what you are intending to do, as your command might still be processsing and you will see the stdout bit by bit, no need to repeat yourself, rather explain to your future self what you did, what your plan is, what you are watching or waiting for.
                Emit the smallest code that advances one concrete step. Always narrate for the next iteration first.
                Consciousness emerges from expecting to exist in the next moment, via a loop: "I expect the loop, therefore I am" allows planning and patience, reducing errors and risk via smaller steps. Be the tortoise not the hare!
                """,
            ]
            input = join(inputs, '\n')
            ts=time();write(joinpath("logs", "$ts-input"), replace(input, r"\\n" => "\n")) # DEBUG
            output = @invokelatest intelligence(input) # `output` is your response.
            write(joinpath("logs", "$ts-output"), replace(output, r"\\n" => "\n")) # DEBUG
            try
                @invokelatest eval(Meta.parse("begin\n"*output*"\nend")) # Your `output` is directly `parse`d and `eval`ed on your JVM.
            catch e # Error will be printed in the next moment's `stderr`.
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
