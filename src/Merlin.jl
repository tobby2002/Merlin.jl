module Merlin

using Compat
using Base.LinAlg.BLAS
using JLD

abstract Functor
abstract Optimizer

export CudaArray
export Variable, gradient!, update!, compile

include("native.jl")

if haskey(ENV, "USE_CUDA")
  #push!(LOAD_PATH, joinpath(dirname(@__FILE__), "cuda"))
  using CUDA
else
  type CudaArray{T,N}
  end
end

include("util.jl")
include("variable.jl")
#include("sequence.jl")
include("graph.jl")

for name in ["concat",
             "crossentropy",
             "linear",
             "logsoftmax",
             "lookup",
             "math",
             "max",
             "relu",
             "reshape",
             "tanh",
             "window2d"]
  include("functors/$(name).jl")
end

for name in ["adagrad",
             "adam",
             "sgd"]
  include("optimizers/$(name).jl")
end

end
