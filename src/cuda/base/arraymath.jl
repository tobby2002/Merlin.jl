import Base: exp, log
import Base: .+, +, .-, -, .*, *

#=
macro elemwise(op)
    quote
        op = $op
        y = CudaArray{T}(size(x))
        t = ctype(T)
        f = @nvrtc """
        $array_h
        __global__ void f(Array<$t,$N> x, Array<$t,$N> y) {
            int idx = blockIdx.x * blockDim.x + threadIdx.x;
            if (idx < y.length()) {
                y(idx) = $op(x(idx));
            }
        } """
        f(x, y, dx=length(y))
        y
    end
end
=#

for op in (:exp, :log)
    @eval begin
        function $op{T,N}(x::CudaArray{T,N})
            op = $op
            y = similar(x)
            t = ctype(T)
            f = @nvrtc """
            __global__ void f($t *x, $t *y, int length) {
                int idx = blockIdx.x * blockDim.x + threadIdx.x;
                if (idx < length) {
                    y[idx] = $op(x[idx]);
                }
            } """
            f(x.ptr, y.ptr, length(x), dx=length(y))
            y
        end
    end
end

for op in (:+, :-)
    @eval begin
        function $op{T,N}(x1::CudaArray{T,N}, x2::CudaArray{T,N})
            size(x1) == size(x2) || throw(DimensionMismatch())
            op = $op
            y = CudaArray{T}(size(x1))
            t = ctype(T)
            f = @nvrtc """
            __global__ void f($t *x1, $t *x2, $t *y, int length) {
                int idx = blockIdx.x * blockDim.x + threadIdx.x;
                if (idx < length) {
                    y[idx] = x1[idx] $op x2[idx];
                }
            } """
            f(x1.ptr, x2.ptr, y.ptr, length(y), dx=length(y))
            y
        end
    end
end

#=
for (op1,op2) in ((:.+,:+), (:.-,:-))
    @eval begin
        function $op1{T,N}(x1::AbstractCudaArray{T,N}, x2::AbstractCudaArray{T,N})
            dims = ntuple(i -> max(size(x1,i),size(x2,i)), N)
            y = CudaArray{T}(dims)
            broadcast!($op2, y, x1, x2)
        end
    end
end
=#

*(x1::CudaMatrix, x2::CudaMatrix) = BLAS.gemm(x1, x2)

import Merlin.add!
add!{T}(y::CudaArray{T}, x::CudaArray{T}) = BLAS.axpy!(T(1), x, y)
