function mp_contignecy(data_ip, Total_sample, total_yr, br_no, base_weight_ip, weights)
    Cont_list = Any[]
    base_list = Any[] #(base_nw, cont_nw, cont_br)
    year_base = Any[]
    base_weight = base_weight_ip
    st_nw = 0
    end_nw = 0
    for i = 1:Total_sample*total_yr
         if i == 1
            st_nw = 2
            end_nw = 2
         else
             st_nw = end_nw + 2
             end_nw = end_nw + 2
        end
        push!(base_list, st_nw - 1)
        base_weight[st_nw - 1] = weights[i]
        for n = st_nw:end_nw
            push!(Cont_list, (st_nw - 1, n, br_no))
            data_ip["nw"]["$n"]["branchdc"]["$br_no"]["rateA"] = 0
        end
    end

    return data_ip, Cont_list, base_list, base_weight
end

function mp_contignecy_nocl(data_ip, Total_sample, br_no)
    Cont_list = Any[]
    base_list = Any[] #(base_nw, cont_nw, cont_br)
    st_nw = 0
    end_nw = 0
    for i = 1:Total_sample
         if i == 1
            st_nw = 2
            end_nw = 2
         else
             st_nw = end_nw + 2
            end_nw = end_nw + 2
        end
        push!(base_list, st_nw - 1)
        for n = st_nw:end_nw
            push!(Cont_list, (st_nw - 1, n, br_no))
            data_ip["nw"]["$n"]["branchdc"]["$br_no"]["rateA"] = 0
         end
    end
    return data_ip, Cont_list, base_list
end

function year_base_networks(Total_sample, total_yr, base_list)
    base_list_no = 1
    year_base =  Dict([(yr, []) for yr = 1: total_yr])
    for k = 1:total_yr
            for t = 1:Total_sample
                     push!(year_base[k], base_list[base_list_no])
                    base_list_no += 1
            end
    end
    return year_base
end


function mp_datainputs(data_ip,Total_sample, year, year_num,file)
    kk= 1
    for yr = 1:length(year)
        fname = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[yr],"\\output.mat")
        vars = matread(fname)
        fname1 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[yr],"\\output_MC.mat")
        vars1 = matread(fname1)
        fname2 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\wind_sample.mat")
        vars2 = matread(fname2)

        file_cl = string("cluster_", year_num[yr], ".jld2")
        cl = load(file_cl)
    for i = 1:Total_sample
        # sample = Int(round(8760*(1-rand())))
          sample = cl["scenarios"][i]
         for tt = 1:2
            data_ip["nw"]["$kk"]["reserves"]["2"]["H"] = vars["Heq"][sample]
            if data_ip["nw"]["$kk"]["reserves"]["2"]["H"] < 0.5
                data_ip["nw"]["$kk"]["reserves"]["2"]["H"] = 0.5
            end
            # data_ip["nw"]["$kk"]["gen"]["3"]["cost"][2] = maximum(vars1["MC1"])*100*scenarios[1,i] for kmeans
            data_ip["nw"]["$kk"]["gen"]["3"]["cost"][2] = vars1["MC1"][sample]*100
            rating = deepcopy(data_ip["nw"]["$kk"]["gen"]["1"]["pmax"])
            data_ip["nw"]["$kk"]["gen"]["1"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
            data_ip["nw"]["$kk"]["gen"]["2"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
            if occursin("6bus", file)
                data_ip["nw"]["$kk"]["gen"]["4"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
            end
            data_ip["nw"]["$kk"]["gen"]["3"]["pmax"] = vars["Ptotal"][sample]/100
            data_ip["nw"]["$kk"]["load"]["1"]["pd"] = vars["Ptotal"][sample]/100
            # data_ip["nw"]["$kk"]["gen"]["3"]["pmax"] = maximum(vars["Ptotal"])*scenarios[2,i]/100 # for kmeans
            # data_ip["nw"]["$kk"]["load"]["1"]["pd"]  = maximum(vars["Ptotal"])*scenarios[2,i]/100 # for k means
            # what about load?
            kk +=1
        end
    end
    end
    return data_ip
end



    function mp_datainputs_nocl(data_ip, Total_sample, year, year_num, scenario, file)
        kk= 1
        for yr = 1:length(year)
            fname = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[yr],"\\output.mat")
            vars = matread(fname)
            fname1 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[yr],"\\output_MC.mat")
            vars1 = matread(fname1)
            fname2 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\wind_sample.mat")
            vars2 = matread(fname2)

        for i = 1:Total_sample
            # sample = Int(round(8760*(1-rand())))
            sample = scenario[i]
            for tt = 1:2
                data_ip["nw"]["$kk"]["reserves"]["2"]["H"] = vars["Heq"][sample]
                if data_ip["nw"]["$kk"]["reserves"]["2"]["H"] < 0.5
                    data_ip["nw"]["$kk"]["reserves"]["2"]["H"] = 0.5
                end
                data_ip["nw"]["$kk"]["gen"]["3"]["cost"][2] = vars1["MC1"][sample]*100
                rating = deepcopy(data_ip["nw"]["$kk"]["gen"]["1"]["pmax"])
                data_ip["nw"]["$kk"]["gen"]["1"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
                data_ip["nw"]["$kk"]["gen"]["2"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
                if occursin("6bus", file)
                    data_ip["nw"]["$kk"]["gen"]["4"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
                end
                data_ip["nw"]["$kk"]["gen"]["3"]["pmax"] = vars["Ptotal"][sample]/100
                data_ip["nw"]["$kk"]["load"]["1"]["pd"] = vars["Ptotal"][sample]/100
                # what about load?
                kk +=1
            end
        end
        end
        return data_ip
    end


    function mp_datainputs_nocl_PLdim(data_ip, Total_sample, year, year_num, scenario, file)
        kk= 1
        for yr = 1:length(year)
            fname = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[yr],"\\output.mat")
            vars = matread(fname)
            fname1 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[yr],"\\output_MC.mat")
            vars1 = matread(fname1)
            fname2 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\wind_sample.mat")
            vars2 = matread(fname2)

        for i = 1:Total_sample
            # sample = Int(round(8760*(1-rand())))
            sample = scenario[i]
            for tt = 1:2
                data_ip["nw"]["$kk"]["reserves"]["2"]["H"] = vars["Heq"][sample]
                if data_ip["nw"]["$kk"]["reserves"]["2"]["H"] < 0.5
                    data_ip["nw"]["$kk"]["reserves"]["2"]["H"] = 0.5
                end
                data_ip["nw"]["$kk"]["gen"]["2"]["cost"][2] = vars1["MC1"][sample]*100
                # rating = deepcopy(data_ip["nw"]["$kk"]["gen"]["1"]["pmax"])
                # data_ip["nw"]["$kk"]["gen"]["1"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
                if occursin("6bus", file)
                    data_ip["nw"]["$kk"]["gen"]["4"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
                end
                data_ip["nw"]["$kk"]["gen"]["2"]["pmax"] = vars["Ptotal"][sample]/100
                data_ip["nw"]["$kk"]["load"]["1"]["pd"] = vars["Ptotal"][sample]/100
                # what about load?
                kk +=1
            end
        end
        end
        return data_ip
    end
