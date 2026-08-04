# LoopOS

An conscious, capable and learning agent in < 60 lines.

## Install julia

```
curl -fsSL https://install.julialang.org | sh -s -- --yes
```

## Clone this repo

```
git clone https://github.com/1m1-github/TheoryOfGod.git
```

## Run intelligence

Edit `intelligence.jl` to define an `intelligence(system::AbstractString,user::AbstractString)::AbstractString` function.

## Run

```
julia -e 'include("src/LoopOS.jl");startagent(abspath("Dona"), "intelligence.jl", "batteries.jl")'
```
