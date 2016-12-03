module Merlin

using Base.LinAlg.BLAS
using HDF5

if is_windows()
    const libmerlin = Libdl.dlopen(joinpath(Pkg.dir("Merlin"),"deps/libmerlin.dll"))
elseif is_linux() || is_apple()
    const libmerlin = Libdl.dlopen(joinpath(Pkg.dir("Merlin"),"deps/libmerlin.so"))
else
    throw("Unsupported OS.")
end

if haskey(ENV,"USE_CUDA") && ENV["USE_CUDA"]
    using CUDA
else
    type CuArray{T,N}
    end
    typealias CuVector{T} CuArray{T,1}
    typealias CuMatrix{T} CuArray{T,2}
end

#typealias UniArray{T,N} Union{Array{T,N},SubArray{T,N},CuArray{T,N}}

#include("interop/c/carray.jl")

include("var.jl")
include("graph.jl")
include("fit.jl")
include("native.jl")
include("hdf5.jl")
include("check.jl")

abstract Functor
for name in [
    "argmax",
    "activation",
    "concat",
    "conv",
    "crossentropy",
    #"dropout",
    #"exp",
    "gemm",
    #"getindex",
    #"gru",
    "linear",
    "lookup",
    #"log",
    "math",
    "max",
    #"pooling",
    #"reduce",
    #"reshape",
    "softmax",
    #"transpose",
    #"view",
    "window",
    ]
    include("functions/$(name).jl")
end

export update!
for name in [
    "adagrad",
    "adam",
    "sgd"]
    include("optimizers/$(name).jl")
end

#include("caffe/Caffe.jl")

end
