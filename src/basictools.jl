using Pkg
Pkg.add(["HTTP", "JSON3", "Base64", "Dates", "SMTPClient", "Serialization", "Gumbo", "Cascadia"])
using HTTP, JSON3, Base64, Dates, SMTPClient, Serialization, Gumbo, Cascadia

"Uses DuckDuckGo API for searching returning a Dict with :title, :snippet and :url keys/"
function web_search(query::String; num_results::Int=10)
    # @info "TOGBasicTools.jl, web_search"
    encoded_query = HTTP.URIs.escapeuri(query)
    url = "https://html.duckduckgo.com/html/?q=$(encoded_query)"
    response = HTTP.get(url)
    html = String(response.body)
    doc = parsehtml(html)
    get_inner(x, result) = text(only(eachmatch(Selector(".result__$x"), result)))
    results = []
    result = collect(eachmatch(Selector(".result.results_links.results_links_deep.web-result"), doc.root))[1]
    for result = eachmatch(Selector(".result.results_links.results_links_deep.web-result"), doc.root)
        push!(results, Dict(
            :title => get_inner("a", result),
            :snippet => get_inner("snippet", result),
            :url => get_inner("url", result),
        ))
    end
    results
end

"Removes HTML tags to extract plain text."
function browse_page(url::String)
    @info "TOGBasicTools.jl, browse_page"
    resp = HTTP.get(url)
    html = String(resp.body)

    function clean_html(url, html)
        dom = parsehtml(html)
        body = only(eachmatch(Selector("body"), dom.root))
        buffer = IOBuffer()

        function walk!(url, buffer, node)
            if node isa HTMLElement
                tag_sym = tag(node)
                tag_sym ∈ (:script, :style) && return
                if tag_sym == :a && haskey(node.attributes, "href")
                    hrefa = node.attributes["href"]
                    if !contains(href, "://")
                        href = "$url$href"
                    end
                    map(n -> walk!(url, buffer, n), children(node))
                    print(buffer, "<", href, "> ")
                    return
                end
                map(n -> walk!(url, buffer, n), children(node))
            elseif node isa HTMLText
                print(buffer, text(node))
            end
        end

        walk!(url, buffer, body)
        strip(String(take!(buffer)))
    end

    clean_html(url, html)
end

"Handles binary download safely."
download_file(url::String, local_path::String) = begin
   @info "TOGBasicTools.jl, download_file" 
    HTTP.download(url, local_path)
end

"""
run_shell(`echo 1`).
Use `expanduser` instead of `~`.
`throw`s on error.
"""
function run_shell(cmd::Cmd)::String
    # @info "TOGBasicTools.jl, run_shell"
    out = IOBuffer()
    err = IOBuffer()
    proc = open(pipeline(cmd; stdout=out, stderr=err), "r")
    wait(proc)
    exception = String(take!(err))
    !isempty(exception) && throw(exception)
    String(take!(out))
end
run_shell(command::String) = run_shell(Cmd(split(command)))

"Supports common HTTP methods like GET POST."
function send_http_request(method::String, url::String, headers::Dict=Dict(), body::String="")
    # @info "TOGBasicTools.jl, send_http_request"
    hpairs = Pair.(keys(headers), values(headers))
    resp = HTTP.request(method, url, hpairs, body)
    String(resp.body)
end

"Handles malformed JSON gracefully."
parse_json(json_str::String) = JSON3.read(json_str)

"""`send_email(["<to@email.org>"], "body", "message")`."""
function send_email(to::Vector{String}, subject::String, message::String)
    # @info "TOGBasicTools.jl, send_email"
    from = "<email@1m1.io>"
    body = get_body(to, from, subject, message)
    # body = get_body(to, from, subject, message; cc, replyto)
    opt = SendOptions(
        isSSL=true,
        username="1@1m1.io",
        passwd=ENV["GMAIL_PASSWORD"])
    url = "smtps://smtp.gmail.com:465"
    send(url, to, from, body, opt)
end
