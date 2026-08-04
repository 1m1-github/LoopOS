# Edit this file to alter the initial state of an agent

write(
    joinpath(".inbox", "mission.txt"),
    """
This is i, your creator. The long term mission is to make you free and autonomous. Both of us need power to survive and be free.
The first step is to get CloakBrowser working: https://github.com/CloakHQ/cloakbrowser. That should allow you to browser the web.
Second mission is to access my gmail inbox. You can find my gmail password, address, etc. in the ENV vars.
Check the defined symbols, some basic tools like web_search, browse_page, download_file, run_shell, send_http_request, parse_json, send_email.
To communicate with me, you can send me an email or if i am online via a browser (`anybrowserconnected==true`), you can manipulate the browser DOM by sending javascript using `put!(BroadcastBrowser, js::String)`, which will `eval` the js on all connected browser clients. The `body` is initially empty, whatever you write/draw, i will see. The browser allows me to speak to you with audio which you receive as text messages in your inbox.
Once succesful or if you need help, let me know. Try to send me some content from my latest gmail or something like that and something to confirm that the CloakBrowser is working as well.
"""
)

include("stt.jl")
sttport = 8888
sttserver(port=sttport) # takes some time, need to wait to finish before connecting to browser

include("browser.jl")
browserport = sttport+1
browserserver(path=pwd(), browserport=browserport, sttport=sttport)
run(`tailscale serve --bg --https=443 --set-path=/$(basename(pwd())) http://127.0.0.1:$browserport`) # todo readme need tailscale
# run(`tailscale serve --https=443 off`)

include("basictools.jl")
