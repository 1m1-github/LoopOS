using PythonCall

const TRANSFORMERS = pyimport("transformers")
const PIPE = TRANSFORMERS.pipeline("image-text-to-text", model="Qwen/Qwen3.6-27B")
const TORCH = pyimport("torch")
# const torchvision = pyimport("torchvision")
# const pillow = pyimport("pillow")
# using CondaPkg
# CondaPkg.add_pip("torchvision")
# CondaPkg.add_pip("pillow")

function intelligence(system, input)
    messages = pylist([
        pydict(
            role="system",
            content=pylist([pydict(type="text", text=system)])
        ),
        pydict(
            role="user",
            content=pylist([
                # pydict(type = "image", url = "https://huggingface.co/datasets/huggingface/documentation-images/resolve/main/p-blog/candy.JPG"),
                pydict(type="text", text=input)
            ])
        )
    ])
    out = PIPE(text=messages,enable_thinking = false, max_new_tokens = 2^12)
    # write("logs/out.txt",string(out))
    # out[0]["generated_text"][2]
    string(out[0]["generated_text"][2]["content"])
    # @info out, typeof(out)
end
