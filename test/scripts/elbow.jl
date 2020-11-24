using DataFrames
using Distributions
using PyPlot
using LinearAlgebra
function makeData()
    groupOne = rand(MvNormal([10.0, 10.0], 10.0 * Matrix{Float64}(I, 2,2)), 100)
    groupTwo = rand(MvNormal([0.0, 0.0], 10 * Matrix{Float64}(I, 2,2)), 100)
    groupThree = rand(MvNormal([15.0, 0.0], 10.0 * Matrix{Float64}(I, 2,2)), 100)
    return hcat(groupOne, groupTwo, groupThree)'
end


data = makeData()
scatter(data[1:100, 1], data[1:100, 2], color="blue")
scatter(data[101:200, 1], data[101:200, 2], color="red")
scatter(data[201:300, 1], data[201:300, 2], color="green")

using StatsBase

mutable struct kMeans
    x::DataFrames.DataFrame
    k::Int
end

function euclidean(sourcePoint, destPoint)
    sum = 0
    for i in 1:length(sourcePoint)
        sum += (destPoint[i] - sourcePoint[i]) ^ 2
    end
    dist = sqrt(sum)
    return dist
end

function minkowski(sourcePoint, destPoint)
    sum = 0
    for i in 1:length(sourcePoint)
        sum += abs(destPoint[i] - sourcePoint[i])
    end
    return sum
end

function calcDist(sourcePoint::Array, destPoint::Array; method="euclidean")

    if length(sourcePoint) != length(destPoint)
        error("The lengths of two arrays are different.")
        return
    end

    if method == "euclidean"
        return euclidean(sourcePoint, destPoint)
    elseif method == "minkowski"
        return minkowski(sourcePoint, destPoint)
    end
end

function classify(kMeans::kMeans)
    dataPointsNum = size(kMeans.x, 1)
    estimatedClass = Array{Int, dataPointsNum}
    direct_sample(1:kMeans.k, estimatedClass)

    while true
        # update representative points
        representativePoints = []
        for representativeIndex in 1:kMeans.k
            groupIndex = find(estimatedClass .== representativeIndex)
            groupData = kMeans.x[groupIndex, :]

            # TODO: check the return type of colwise
            representativePoint = [ valArray[1] for valArray in colwise(mean, groupData) ]
            push!(representativePoints, representativePoint)
        end

        # update group belonging
        tempEstimatedClass = Array{Int}(dataPointsNum)
        for dataIndex in 1:dataPointsNum
            dataPoint = Array(kMeans.x[dataIndex, :])
            distances = Array{Float64}(kMeans.k)
            for representativeIndex in 1:kMeans.k
                distances[representativeIndex] = calcDist(dataPoint, representativePoints[representativeIndex])
            end

            # TODO: check the existence of argmin
            tempEstimatedClass[dataIndex] = sortperm(distances)[1]
        end

        if estimatedClass == tempEstimatedClass
            break
        end
        estimatedClass = tempEstimatedClass
    end
    return estimatedClass
end

    kmeansElbow = kMeans(DataFrame(data), 3)

    predictedClassElbow = classify(kmeansElbow)
