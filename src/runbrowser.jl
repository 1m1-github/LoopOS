include("stt.jl")
include("broadcastbrowser.jl")

function runbrowser(; path, browserport, sttport)
    JSLISTEN = raw"""
    (async()=>{
    window.AUDIOCTX=new AudioContext({sampleRate:16000})
    const workletCode=`
    class PCMProcessor extends AudioWorkletProcessor{
    process(inputs){
    const input=inputs[0]
    if(input&&0<input.length){
    const data=input[0]
    const pcm=new Int16Array(data.length)
    for(let i=0;i<data.length;i++)pcm[i]=Math.max(-32768,Math.min(32767,data[i]*32767|0))
    this.port.postMessage(pcm.buffer,[pcm.buffer])
    }
    return true
    }
    }
    registerProcessor('pcm-processor',PCMProcessor)
    `
    const blob=new Blob([workletCode],{type:'application/javascript'})
    await window.AUDIOCTX.audioWorklet.addModule(URL.createObjectURL(blob))
    window.WORKLETNODE=new AudioWorkletNode(window.AUDIOCTX,'pcm-processor')
    window.IS_RECORDING=false
    window.AUDIO_BUFFER=[]
    window.TOTAL_SAMPLES=0
    window.AUDIOSTREAM=null
    window.AUDIOSOURCE=null
    const flush=()=>{
    if(window.TOTAL_SAMPLES===0)return
    const combined=new Int16Array(window.TOTAL_SAMPLES)
    let offset=0
    for(const c of window.AUDIO_BUFFER){
    combined.set(c,offset)
    offset+=c.length
    }
    fetch(`${window.BASE}/audio`,{method:'POST',body:combined.buffer,headers:{'Content-Type':'application/octet-stream'}}).catch(()=>{})
    window.AUDIO_BUFFER=[]
    window.TOTAL_SAMPLES=0
    }
    window.WORKLETNODE.port.onmessage=e=>{
    if(!window.IS_RECORDING)return
    const pcm=new Int16Array(e.data)
    window.AUDIO_BUFFER.push(pcm)
    window.TOTAL_SAMPLES+=pcm.length
    }
    const start=async()=>{
    if(window.IS_RECORDING)return
    window.IS_RECORDING=true
    window.AUDIO_BUFFER=[]
    window.TOTAL_SAMPLES=0
    try{
    window.AUDIOSTREAM=await navigator.mediaDevices.getUserMedia({audio:true})
    window.AUDIOSOURCE=window.AUDIOCTX.createMediaStreamSource(window.AUDIOSTREAM)
    window.AUDIOSOURCE.connect(window.WORKLETNODE)
    if(window.AUDIOCTX.state==='suspended')await window.AUDIOCTX.resume()
    }catch(e){
    window.IS_RECORDING=false
    }
    }
    const stop=()=>{
    if(!window.IS_RECORDING)return
    window.IS_RECORDING=false
    if(window.AUDIOSOURCE){
    window.AUDIOSOURCE.disconnect()
    window.AUDIOSOURCE=null
    }
    if(window.AUDIOSTREAM){
    window.AUDIOSTREAM.getTracks().forEach(t=>t.stop())
    window.AUDIOSTREAM=null
    }
    flush()
    }
    document.addEventListener('pointerdown',e=>{e.preventDefault();start()})
    document.addEventListener('pointerup',stop)
    document.addEventListener('pointercancel',stop)
    })()
    """

    awakenbroadcastbrowser(
        port=browserport,
        connect=(_) -> put!(BroadcastBrowser, JSLISTEN),
        functions=Dict(
            "/audio" => (data) -> begin
                text = transcribe(data=data, port=sttport)
                isempty(text) || write(joinpath(path, ".inbox", string(time()) * "-browser-audio.txt"), text)
            end))

    wait(Condition())
end
