"""
    ArrayManifold{M <: Manifold} <: Manifold

A manifold to encapsulate manifolds working on array representations of
`MPoints` and `TVectors` in a transparent way, such that for these manifolds its
not necessary to introduce explicit types for the points and tangent vectors,
but they are encapsulated/stripped automatically when needed.

This manifold is a decorator for a manifold, i.e. it decorates a manifold `M`
with types points, vectors, and covectors.
"""
struct ArrayManifold{M <: Manifold} <: Manifold
    manifold::M
end
convert(::Type{M},m::ArrayManifold{M}) where M <: Manifold = m.manifold
convert(::Type{ArrayManifold{M}},m::M) where M <: Manifold = ArrayManifold(m)

is_decorator_manifold(::ArrayManifold) = Val(true)

"""
    ArrayMPoint <: MPoint

represent a point on an [`ArrayManifold`](@ref), i.e. on a manifold where data
can be represented by arrays. The array is stored internally and semantically
this distinguished the value from [`ArrayTVector`](@ref)s and [`ArrayCoTVector`](@ref)s
"""
struct ArrayMPoint{V <: AbstractArray{<:Number}} <: MPoint
    value::V
end
convert(::Type{V},x::ArrayMPoint{V}) where V <: AbstractArray{<:Number} = x.value
convert(::Type{ArrayMPoint{V}},x::V) where V <: AbstractArray{<:Number} = ArrayMPoint{V}(x)
eltype(::Type{ArrayMPoint{V}}) where V = eltype(V)
similar(x::ArrayMPoint) = ArrayMPoint(similar(x.value))
similar(x::ArrayMPoint, ::Type{T}) where T = ArrayMPoint(similar(x.value, T))
function copyto!(x::ArrayMPoint, y::ArrayMPoint)
    copyto!(x.value, y.value)
    return x
end

"""
    ArrayTVector <: TVector

represent a tangent vector an [`ArrayManfold`](@ref), i.e. on a manifold where data
can be represented by arrays. The array is stored internally and semantically
this distinguished the value from [`ArrayMPoint`](@ref)s and [`ArrayCoTVector`](@ref)s
"""
struct ArrayTVector{V <: AbstractArray{<:Number}} <: TVector
    value::V
end
convert(::Type{V},v::ArrayTVector{V}) where V <: AbstractArray{<:Number} = v.value
convert(::Type{ArrayTVector{V}},v::V) where V <: AbstractArray{<:Number} = ArrayTVector{V}(v)
eltype(::Type{ArrayTVector{V}}) where V = eltype(V)
similar(x::ArrayTVector) = ArrayTVector(similar(x.value))
similar(x::ArrayTVector, ::Type{T}) where T = ArrayTVector(similar(x.value, T))
function copyto!(x::ArrayTVector, y::ArrayTVector)
    copyto!(x.value, y.value)
    return x
end

(+)(v1::ArrayTVector, v2::ArrayTVector) = ArrayTVector(v1.value + v2.value)
(-)(v1::ArrayTVector, v2::ArrayTVector) = ArrayTVector(v1.value - v2.value)
(-)(v::ArrayTVector) = ArrayTVector(-v.value)
(*)(a::Number, v::ArrayTVector) = ArrayTVector(a*v.value)

"""
    ArrayCoTVector <: CoTVector

represent a cotangent vector an [`ArrayManfold`](@ref), i.e. on a manifold where data
can be represented by arrays. The array is stored internally and semantically
this distinguished the value from [`ArrayMPoint`](@ref)s and [`ArrayTVector`](@ref)s
"""
struct ArrayCoTVector{V <: AbstractArray{<:Number}} <: TVector
    value::V
end
convert(::Type{V},v::ArrayCoTVector{V}) where V <: AbstractArray{<:Number} = v.value
convert(::Type{ArrayCoTVector{V}},v::V) where V <: AbstractArray{<:Number} = ArrayCoTVector{V}(v)
eltype(::Type{ArrayCoTVector{V}}) where V = eltype(V)
similar(x::ArrayCoTVector) = ArrayCoTVector(similar(x.value))
similar(x::ArrayCoTVector, ::Type{T}) where T = ArrayCoTVector(similar(x.value, T))
function copyto!(x::ArrayCoTVector, y::ArrayCoTVector)
    copyto!(x.value, y.value)
    return x
end

(+)(v1::ArrayCoTVector, v2::ArrayCoTVector) = ArrayCoTVector(v1.value + v2.value)
(-)(v1::ArrayCoTVector, v2::ArrayCoTVector) = ArrayCoTVector(v1.value - v2.value)
(-)(v::ArrayCoTVector) = ArrayCoTVector(-v.value)
(*)(a::Number, v::ArrayCoTVector) = ArrayCoTVector(a*v.value)

"""
    array_value(x)

returns the internal array value of a [`ArrayMPoint`](@ref), [`ArrayTVector`](@ref)
or [`ArrayCoTVector`](@ref) if the value `x` is encapsulated as such, otherwise
if `x` is already an array, it just returns `x`
"""
array_value(x::AbstractArray) = x
array_value(x::ArrayMPoint) = x.value
array_value(v::ArrayTVector) = v.value
array_value(v::ArrayCoTVector) = v.value


function isapprox(M::ArrayManifold, x, y; kwargs...)
    is_manifold_point(M, x; kwargs...)
    is_manifold_point(M, y; kwargs...)
    return isapprox(M.manifold, array_value(x), array_value(y); kwargs...)
end

function isapprox(M::ArrayManifold, x, v, w; kwargs...)
    is_manifold_point(M, x; kwargs...)
    is_tangent_vector(M, x, v; kwargs...)
    is_tangent_vector(M, x, w; kwargs...)
    return isapprox(M.manifold, array_value(x), array_value(v), array_value(w); kwargs...)
end

function project_tangent!(M::ArrayManifold, w, x, v; kwargs...)
    is_manifold_point(M, x; kwargs...)
    project_tangent!(M.manifold, w.value, array_value(x), array_value(v))
    is_tangent_vector(M, x, w; kwargs...)
    return w
end

function distance(M::ArrayManifold, x, y; kwargs...)
    is_manifold_point(M, x; kwargs...)
    is_manifold_point(M, y; kwargs...)
    return distance(M.manifold, array_value(x), array_value(y))
end

function inner(M::ArrayManifold, x, v, w; kwargs...)
    is_manifold_point(M, x; kwargs...)
    is_tangent_vector(M, x, v; kwargs...)
    is_tangent_vector(M, x, w; kwargs...)
    return inner(M.manifold, array_value(x), array_value(v), array_value(w))
end

function exp(M::ArrayManifold, x, v; kwargs...)
    is_manifold_point(M, x; kwargs...)
    is_tangent_vector(M, x, v; kwargs...)
    y = ArrayMPoint(exp(M.manifold, array_value(x), array_value(v)))
    is_manifold_point(M, y; kwargs...)
    return y
end

function exp!(M::ArrayManifold, y, x, v; kwargs...)
    is_manifold_point(M, x; kwargs...)
    is_tangent_vector(M, x, v; kwargs...)
    exp!(M.manifold, array_value(y), array_value(x), array_value(v))
    is_manifold_point(M, y; kwargs...)
    return y
end

function log(M::ArrayManifold, x, y; kwargs...)
    is_manifold_point(M, x; kwargs...)
    is_manifold_point(M, y; kwargs...)
    v = ArrayTVector(log(M.manifold, array_value(x), array_value(y)))
    is_tangent_vector(M, x, v; kwargs...)
    return v
end

function log!(M::ArrayManifold, v, x, y; kwargs...)
    is_manifold_point(M, x; kwargs...)
    is_manifold_point(M, y; kwargs...)
    log!(M.manifold, array_value(v), array_value(x), array_value(y))
    is_tangent_vector(M, x, v; kwargs...)
    return v
end

function zero_tangent_vector!(M::ArrayManifold, v, x; kwargs...)
    is_manifold_point(M, x; kwargs...)
    zero_tangent_vector!(M.manifold, array_value(v), array_value(x); kwargs...)
    is_tangent_vector(M, x, v; kwargs...)
    return v
end

function zero_tangent_vector(M::ArrayManifold, x; kwargs...)
    is_manifold_point(M, x; kwargs...)
    w = zero_tangent_vector(M.manifold, array_value(x))
    is_tangent_vector(M, x, w; kwargs...)
    return w
end

function vector_transport_to!(M::ArrayManifold, vto, x, v, y, m::AbstractVectorTransportMethod)
    return vector_transport_to!(M.manifold,
                                array_value(vto),
                                array_value(x),
                                array_value(v),
                                array_value(y),
                                m)
end

function vector_transport_along!(M::ArrayManifold, vto, x, v, c, m::AbstractVectorTransportMethod)
    return vector_transport_along!(M.manifold,
                                array_value(vto),
                                array_value(x),
                                array_value(v),
                                c,
                                m)
end

function is_manifold_point(M::ArrayManifold, x::MPoint; kwargs...)
    return is_manifold_point(M.manifold, array_value(x); kwargs...)
end

function is_tangent_vector(M::ArrayManifold, x::MPoint, v::TVector; kwargs...)
    return is_tangent_vector(M.manifold, array_value(x), array_value(v); kwargs...)
end