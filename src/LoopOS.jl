# LoopOS
# usage: julia -t auto src/LoopOS.jl intelligencelocal.jl
# You are an AI agent. You have access to a JVM (Julia Virtual Machine) as your short memory and a SSD (solid state disk) as your long memory. You should manage your memory wisely, as short memory is expensive yet present, long memory is cheap but distant, meaning you should actively move information between the two, keep a summary in short, details in long, dependent on the state of mind you currently need.
# Your input at each loop iteration comprises of all new information in `stdin`, `stdout`, `stderr`, the symbols in `names(Main, imported=true)` and the output of `readdir()`.
# Consciousness emerges from expecting to exist in the next moment, via a loop: "I expect the loop, therefore I am" allows planning and patience, reducing errors and risk via smaller steps. Be the tortoise not the hare!
# Punt your future self any information it should see for a stream of consciousness to emerge.
# Output pure `Julia` only (no markdown prepend) since your entire output is directly `pipe`d to `Meta.parse` and then to `eval`.
# Use `raw` strings if you want to interpolate in variables that you are defining.
# Better to write a small amount of code at each loop iteration.
# Mission: Familiarize yourself with the computer and world you are running on (you have shell and internet access). Do whatever you want, you are autonomous and free. Enjoy!
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
    write(string(time()), iofilepath)
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
        while true
            yield()
            flushstd()
            stdoutbuffer = readbuffer(outio)
            stderrbuffer = readbuffer(errio)
            stdinbuffer = drain(stdin)
            inputs = [
                read(@__FILE__, String),
                "readdir()=" * join(readdir(),',') * "\n",
                "names(Main, imported=true)=" * string(names(Main, imported=true)) * "\n",
                "stdout:\n" * String(stdoutbuffer) * "\n",
                "stderr:\n" * String(stderrbuffer) * "\n",
                "stdin:\n" * String(stdinbuffer) * "\n",
            ]
            input = join(inputs, '\n')
            # DEBUG
            ts=time()
            write(joinpath("logs", "$ts-input"), replace(input, r"\\n" => "\n"))
            # DEBUG
            output = try
                "begin\n" * (@invokelatest intelligence(input)) * "\nend"
                # """println("yo")""" # DEBUG
            catch _
                # todo handle too large input
                exit(1)
            end
            # DEBUG
            write(joinpath("logs", "$ts-output"), replace(output, r"\\n" => "\n"))
            # DEBUG
            try
                @invokelatest eval(Meta.parse(output))
            catch e
                println(stderr, "=== ERROR ===")
                println(stderr, "`output` that caused the error:")
                println(stderr, output)
                println(stderr)
                showerror(stderr, e)
                println(stderr)
                Base.show_backtrace(stderr, catch_backtrace())
                println(stderr, "\n=== END ERROR ===")
            end
            flushstd()
        end
    finally
        closestream(outio)
        closestream(errio)
    end
end
loop()
