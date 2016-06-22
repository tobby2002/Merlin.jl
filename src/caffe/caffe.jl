module Caffe

using ProtoBuf
import ..Merlin, ..Merlin.Var

include("proto/caffe_pb.jl")

function gksp(p)
  ksize = p.kernel_h > 0 ? (p.kernel_h, p.kernel_w) : (p.kernel_size, p.kernel_size)
  stride = p.stride_h > 0 ? (p.stride_h, p.stride_w) : (p.stride, p.stride)
  pad = p.pad_h > 0 ? (p.pad_h, p.pad_w) : (p.pad, p.pad)
  map(Int,ksize), map(Int,stride), map(Int,pad)
end

function conv(layer)
  blobs = layer.blobs
  w = blobs[1].data
  b = length(blobs) > 1 ? blobs[2].data : nothing
  num = blobs[1].num > 0 ? blobs[1].num : blobs[1].shape.dim[1]
  channels = blobs[1].channels > 0 ? blobs[1].channels : blobs[1].shape.dim[2]
  param = layer.convolution_param
  ksize, stride, pad = gksp(param)

  if param.group == 1
    w = reshape(w, (ksize[1],ksize[2],Int(channels),Int(num)))
  end
  Merlin.Conv(Var(w), Var(b), stride, pad)
end

"""
Load Caffe model.
"""
function load(path)
  np = open(path) do io
    readproto(io, NetParameter())
  end
  dict = Dict()
  for l in np.layers
    dict[l.name] = l
  end
  dict
end

function load(path)
  np = open(path) do io
    readproto(io, NetParameter())
  end
  ltype = __enum_V1LayerParameter_LayerType()
  x = Merlin.Var(:x)
  d = []
  for l in (length(np.layer) > 0 ? np.layer : np.layers)
    if l._type == ltype.CONVOLUTION || l._type == "Convolution"
      f = conv(l)
      #x = f(x)
    elseif l._type == ltype.POOLING || l._type == "Pooling"
      f = pooling(l)
      x = f(x)
    elseif l._type == ltype.RELU || l._type == "ReLU"
      x = Merlin.relu(x)
    elseif l._type == ltype.DATA || l._type == "Data"
      f = data(l)
      #x = f(x)
    elseif l._type == ltype.SOFTMAX_LOSS || l._type == "SoftmaxWithLoss"
      f = softmax_loss(l)
      #x = f(x)
    else
      f = nothing
    end
    push!(d, (l.name,typeof(f),l._type))
  end
  x,d
end

end
