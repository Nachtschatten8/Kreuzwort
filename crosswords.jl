#!/usr/bin/env julia
using HTTP, JSON

# port
PORT = parse(Int,get(ENV,"KREUZWORTRÄTSELER_PORT","8082"))

function match(pattern,word)
    if length(word) != length(pattern)
        return false
    end

    pattern_lower = lowercase(pattern)
    for (w,p) in zip(word, pattern_lower)
        if (p != '*'  ) && (p != lowercase(w))
            return false
        end
    end
    return true
end

function search(pattern,words)
    return [word
            for word in words
            if match(pattern,word)]
end

function suche(req::HTTP.Request)
    paths = splitpath(req.target)
    sprache = paths[end-1]
    pattern = paths[end]
    #pattern = HTTP.getNextId()
    @show sprache,pattern
    candidates = search(pattern,wordlist[sprache])
    return HTTP.Response(
        200,
        ["Content-Type" => "application/json"],
        body = JSON.json(Dict("candidates" => candidates)))
end

function index(req::HTTP.Request)
    return HTTP.Response(
        200,
        ["Content-Type" => "text/html"],
        body = read(joinpath(dirname(@__FILE__),"index.html")))
end



loadwordlist(lang) = readlines(joinpath(dirname(@__FILE__),lang * ".txt"))

wordlist = Dict(
    "D" => loadwordlist("Deutsch"),
    "F" => loadwordlist("Französisch"))

function http()
    #const ROUTER= HTTP.Router()
    ROUTER = HTTP.Router()
    HTTP.@register(ROUTER,"GET","/api/Kreuzwortr%C3%A4tseler/suche/*/*",suche)
    HTTP.@register(ROUTER,"GET","/",index)

    println("Öffne http://localhost:$(PORT)")
    run(`xdg-open http://localhost:$(PORT)/`)

    HTTP.serve(ROUTER, HTTP.Sockets.localhost, PORT)
end

function tui()
    lang = ""

    while !(lang in ["D","F"])
        print("Welche Sprache? D für Deutsch und F für Französisch: ")
        lang = readline()
    end

    example = Dict("D" => "Hau*",
                   "F" => "maiso*")

    words = wordlist[lang]

    println("Tippe Ende zu beenden.")

    while true
        print("Bitte gebe ein Wort ein und ersetze unbekannte Buchstaben durch * (zum Beispiel $(example[lang])): ")
        pattern = readline()

        if pattern == "Ende"
            break
        end
        
        candidates = search(pattern,words)
        if length(candidates) == 0
            println("Keine passenden Wörter gefunden.")
        else
            println("Mögliche Wörter:")
            println.(candidates)
            println()
        end
    end
end

if (length(ARGS) > 0) && (ARGS[1] == "--http")
    http()
else
    tui()
end
