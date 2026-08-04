struct BatchProcessor{T}
    pending::Channel{T}
    notify::Channel{Nothing}
    BatchProcessor{T}() where T = new(Channel{T}(Inf), Channel{Nothing}(1))
end
function Base.put!(bp::BatchProcessor{T}, item::T) where T
    put!(bp.pending, item)
    isready(bp.notify) || put!(bp.notify, nothing)
end
function start!(f, bp::BatchProcessor{T}) where T
    while true 
        yield()
        take!(bp.notify)
        while true 
            yield()
            batch = T[]
            while isready(bp.pending)
                yield()
                push!(batch, take!(bp.pending))
            end
            isempty(batch) && break
            # todo add attention?
            f(batch)
        end
    end
end
