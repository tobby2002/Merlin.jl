module CUDA

if is_windows()
    const libcuda = Libdl.find_library(["nvcuda"])
    const libcudart =  Libdl.find_library(["cudart64_80","cudart64_75"])
else
    const libcuda = Libdl.find_library(["libcuda"])
    const libcudart = Libdl.find_library(["libcudart"])
end
isempty(libcuda) && throw("CUDA driver library cannot be found.")
isempty(libcudart) && throw("CUDA runtime library cannot be found.")

function check_curesult(status)
    status == CUDA_SUCCESS && return nothing
    p = Ptr{UInt8}[0]
    cuGetErrorString(status, p)
    throw(unsafe_string(p[1]))
end

function checkerror(error)
    error == cudaSuccess && return nothing
    p = Ptr{UInt8}[0]
    cuGetErrorString(status, p)
    throw(unsafe_string(p[1]))
end

p = Cint[0]
ccall((:cudaDriverGetVersion,libcudart), UInt32, (Ptr{Cint},), p)
const driver_version = Int(p[1])
p = Cint[0]
ccall((:cudaRuntimeGetVersion,libcudart), UInt32, (Ptr{Cint},), p)
const runtime_version = Int(p[1])

const major = div(driver_version, 1000)
const minor = div(driver_version - major*1000, 10)

include("lib/$(major).$(minor)/libcuda.jl")
include("lib/$(major).$(minor)/libcuda_types.jl")
include("lib/$(major).$(minor)/libcudart.jl")
include("lib/$(major).$(minor)/libcudart_types.jl")

info("CUDA driver version: $driver_version")
info("CUDA runtime version: $runtime_version")

include("device.jl")
include("function.jl")
include("headers.jl")

setdevice(0)
infodevices()

ctype(::Type{Int64}) = :int
ctype(::Type{Float32}) = :float
ctype(::Type{Float64}) = :double

include("base/pointer.jl")
include("base/abstractarray.jl")
include("base/array.jl")
include("base/subarray.jl")
include("base/arraymath.jl")
include("base/broadcast.jl")
include("base/reducedim.jl")

include("Interop.jl")
include("NVRTC.jl")
include("CUBLAS.jl")
using .CUBLAS

#=

include("base/pointer.jl")
include("base/abstractarray.jl")
include("base/array.jl")
include("base/arraymath.jl")
include("base/broadcast.jl")
include("base/headers.jl")
include("base/reducedim.jl")
include("base/subarray.jl")

include("Interop.jl")

##### NVRTC #####
include("NVRTC.jl")

##### CUBLAS #####
include("CUBLAS.jl")
using .CUBLAS

import ..Merlin: Var
for name in [
    "activation",
    "argmax",
    ]
    include("functions/$(name).jl")
end
include("cudnn/CUDNN.jl")
using .CUDNN

import Merlin.add!
add!{T}(y::CuArray{T}, x::CuArray{T}) = CUBLAS.axpy!(T(1), x, y)
=#

end
