using ParallelKMeans, RDatasets, Plots
using Statistics, MAT, Clustering, JLD2
using FileIO
using Distances, Clustering, Statistics
k = 10

function clustering_yearwise(whichyear, k)
# whichyear = "2035"
        year = string("NAT_",whichyear, "_Generation")
        data_ip =  Array{Float64}(undef, 8760, 4)
        fname = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year,"\\output.mat")
        vars = matread(fname)
        fname1 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year,"\\output_MC.mat")
        vars1 = matread(fname1)
        fname2 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\wind_sample.mat")
        vars2 = matread(fname2)
        for i = 1:8760
                     # if vars["Heq"][i] < 0.5
                     #         vars["Heq"][i] = 0.5
                     # end
                     data_ip[i,1] = vars["Heq"][i]/(maximum(vars["Heq"])) #inertia
                     data_ip[i,2] = vars1["MC1"][i]/(maximum(vars1["MC1"])) # gen cost
                     data_ip[i,3] = vars2["winddata"][i]/maximum(vars2["winddata"]) #wind gen
                     data_ip[i,4] = vars["Ptotal"][i]/(maximum(vars["Ptotal"])) #total gen and demand
        end
        D = pairwise(Euclidean(), data_ip', data_ip')
        result = Clustering.kmedoids(D, k)

        # kk = [mean(Clustering.silhouettes(Clustering.kmedoids(D, k), D)) for k = 2:50]

        # result.medoids[result.assignments]
        # result_kmeans = Clustering.kmeans(data_ip', k)
        # b1 = [Clustering.kmedoids(D, i).totalcost for i = 2:100]
        # plot(b1)
        # b2 = [ParallelKMeans.kmeans(data_ip', i, n_threads=1; tol=1e-6, max_iters=300, verbose=false).totalcost for i = 2:100]
        # plot(b2)
        # b3 = [ParallelKMeans.kmeans(data_ip', i; tol=1e-6, max_iters=300, verbose=false).totalcost for i = 2:10]
        # plot(b3)
        return result
end

function clustering_output(result, k)
        weights =[]
        scenarios = []
        for i = 1:k
                wgt = count(x->x == i, result.assignments)/8760
                push!(weights, wgt)
                scenarios = result.medoids
        end
        return weights, scenarios
end

year = ["2025","2030","2035","2040","2045","2050"]
for i = 1:length(year)
        whichyear = year[i]
        result = clustering_yearwise(whichyear, k)
        weights, scenarios = clustering_output(result, k)
        @save string("cluster_",whichyear,".jld2") scenarios weights
end

# scatter(data_ip[:,1], data_ip[:,2], color=:lightrainbow,marker_z=result.assignments, legend=false)
# plot(data_ip[:,2])

function collect_scenario(year)
        scenario = []
        weight = []
        for i = 1:length(year)
                file = string("cluster_", year[i], ".jld2")
                var = load(file)
                append!(scenario, var["scenarios"])
                append!(weight, var["weights"])
        end
        return scenario, weight
end
#
scenario, weight = collect_scenario(year)
#
@save "cluster.jld2" scenarios = scenario weights = weight
# example 1
# X1 = [rand(1, 10); rand(1, 10) ; rand(1, 10); rand(1, 10)]
# # X1 = round.(Int, X)
# result = Clustering.kmeans(X1, 5)
# D = pairwise(Euclidean(), X1, X1)
# kk = Clustering.silhouettes(result, D)
# mean(kk)
# # or
# b = [ParallelKMeans.kmeans(X1, i, n_threads=1; tol=1e-6, max_iters=300, verbose=false).totalcost for i = 2:10]
# plot(b)

# example 2
# iris = dataset("datasets", "iris"); # load the data
# features = collect(Matrix(iris[:, 1:4])'); # features to use for clustering
# result = kmeans(features, 5); # run K-means for the 3 clusters
# scatter(iris.PetalLength, iris.PetalWidth, marker_z=result.assignments,
#       color=:lightrainbow, legend=false)
# D = pairwise(Euclidean(), features, features)
# kk = silhouettes(result, D)
# mean(kk) # score reduces above certain value
# # or
# b = [ParallelKMeans.kmeans(features, i, n_threads=1; tol=1e-6, max_iters=300, verbose=false).totalcost for i = 2:20]

# using ParallelKMeans, RDatasets, Plots
# # load the data
# iris = dataset("datasets", "iris");
# # features to use for clustering
# features = collect(Matrix(iris[:, 1:4])');
# # various artifacts can be accessed from the result i.e. assigned labels, cost value etc
# result = kmeans(features, 3);
# # plot with the point color mapped to the assigned cluster index
# scatter(iris.PetalLength, iris.PetalWidth, marker_z=result.assignments,
#         color=:lightrainbow, legend=false)
# # Single Thread Implementation of Lloyd's Algorithm
# b = [ParallelKMeans.kmeans(features, i, n_threads=1; tol=1e-6, max_iters=300, verbose=false).totalcost for i = 2:10]
# # Multi-threaded Implementation of Lloyd's Algorithm by default
# c = [ParallelKMeans.kmeans(features, i; tol=1e-6, max_iters=300, verbose=false).totalcost for i = 2:10]
