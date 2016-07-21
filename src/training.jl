export fit

function fit(decode, lossfun, opt, xs, ys)
    loss = 0.0
    for i in randperm(length(xs))
        z = decode(xs[i])
        out = lossfun(ys[i], z)
        loss += sum(out.data)
        vars = gradient!(out)
        for v in vars
            opt(v.data, v.grad)
        end
    end
    loss
end
