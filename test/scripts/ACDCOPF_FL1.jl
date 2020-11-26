import PowerModelsACDC;
const _PMACDC = PowerModelsACDC;
import PowerModels;
const _PM = PowerModels;
import InfrastructureModels;
const _IM = InfrastructureModels;
import JuMP
import Gurobi
using MAT
using XLSX
using JLD2
using Statistics
include("basencont_nw.jl")

Total_sample = 500  # sample per year
total_yr = 6# the years in horizon, data coming from excels
period = "multi" # single or multi

# Prot_system = "FS_MDCCB"
Prot_system_coll = ["FS_HDCCB", "NS_CB", "Permanentloss"]
curtailed_gen = [1,2] #geneartor numbers # change also constraint max(), generating power,file name
syncarea = 2
max_curt = 0
@load "scenario_500.jld2"
for proti = 1:3
    Prot_system = Prot_system_coll[proti]
    file = "./test/data/4bus_OPF.m"
    data_sp = _PM.parse_file(file)
    _PMACDC.process_additional_data!(data_sp)

    include("bkgrnd_cal.jl")
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer, "Presolve" => -1, "MIPGap" => 0.1)

    no_nw = 2 * Total_sample*total_yr
    data_mp = multi_network(file, no_nw)
    year = ["NAT_2025_Generation", "NAT_2030_Generation", "NAT_2035_Generation", "NAT_2040_Generation", "NAT_2045_Generation", "NAT_2050_Generation"]
    year_num = ["2025", "2030", "2035", "2040", "2045", "2050"]
    # year = ["NAT_2050_Generation"]
    yr = 1

    # @load "cluster.jld2"

    data_ps = mp_datainputs_nocl(deepcopy(data_mp), Total_sample, year, year_num, scenario_500, file)
    data_cont, Cont_list, base_list = mp_contignecy_nocl(deepcopy(data_ps), Total_sample*total_yr, 2)
    year_base = year_base_networks(Total_sample, total_yr, base_list)

    if Prot_system == "FS_HDCCB" || Prot_system == "FS_MDCCB"
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "process_data_internally" => false, "FSprotection" => true, "NSprotection" => false,
    "Permanentloss" => false, "Cont_list" => Cont_list,"base_list" => base_list,"Total_sample" =>Total_sample, "curtailed_gen" => curtailed_gen, "max_curt" => max_curt, "syncarea" => syncarea, "year_base" => year_base, "total_yr" => total_yr)
    elseif Prot_system == "NS_CB" || Prot_system == "NS_FB"
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "process_data_internally" => false, "FSprotection" => false, "NSprotection" => true,
    "Permanentloss" => false, "Cont_list" => Cont_list,"base_list" => base_list,"Total_sample" =>Total_sample, "curtailed_gen" => curtailed_gen, "max_curt" => max_curt, "syncarea" => syncarea,  "year_base" => year_base, "total_yr" => total_yr)
    else
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "process_data_internally" => false, "FSprotection" => false, "NSprotection" => false,
    "Permanentloss" => true, "Cont_list" => Cont_list,"base_list" => base_list,"Total_sample" =>Total_sample, "curtailed_gen" => curtailed_gen, "max_curt" => max_curt, "syncarea" => syncarea, "year_base" => year_base, "total_yr" => total_yr)
    end

    if period == "single"   push!(s, "multiperiod"=> false)
    elseif period == "multi"  push!(s, "multiperiod"=> true )
    end

    @assert ( s["FSprotection"] == true && (Prot_system == "FS_HDCCB" || Prot_system == "FS_MDCCB") ) || (s["NSprotection"] == true && (Prot_system == "NS_CB" || Prot_system == "NS_FB"))|| (Prot_system == "Permanentloss" && s["NSprotection"] == false && s["FSprotection"] == false)
    conv_rate = Int(data_cont["nw"]["1"]["convdc"]["1"]["Pacmax"]*100)
    if occursin("4bus", file)
        filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\injection\\",conv_rate,"MW\\",Prot_system,"_s.xlsx")
    elseif occursin("6bus", file)
        filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\injection\\",conv_rate,"MW\\",Prot_system,"_s.xlsx")
    end

    for (n,nw) in data_cont["nw"]
                for (r,reserves) in nw["reserves"]
                     if Prot_system == "FS_HDCCB"; reserves["Tcl"] = 0.148
                     elseif Prot_system == "FS_MDCCB"; reserves["Tcl"] = 0.293
                     elseif Prot_system == "NS_FB"; reserves["Tcl"] = 0.100
                      elseif Prot_system == "NS_CB"; reserves["Tcl"] = 0.150
                     elseif Prot_system == "Permanentloss"; reserves["Tcl"] = 100
                     end
                 end
     end

    resultDC1 = _PMACDC.run_acdcscopf_nocl(data_cont, _PM.DCPPowerModel, gurobi, multinetwork = true;  setting = s)
    display_keyindictionary_OPF(resultDC1, "isbuilt", "Pgg")
    display(curtailed_gen)
    curtail, maxFFR, maxFCR, meanFFR, meanFCR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
     XLSX.openxlsx(filepath, mode="w") do xf
        sheet = xf[1]
        sheet["$(string("A",1))"] = data_cont["nw"]["1"]["reserves"]["2"]["H"]
        sheet["$(string("A",2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
        sheet["$(string("A",3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
        sheet["$(string("A",4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
        sheet["$(string("A",5))"] = resultDC1["solution"]["nw"]["1"]["Cont"]
        # sheet["$(string("A",5))"] = sum(curtail)
        sheet["$(string("A",6))"] = resultDC1["objective"]
        sheet["$(string("A",7))"] = maxFFR
        sheet["$(string("A",8))"] = maxFCR
        sheet["$(string("A",9))"] = resultDC1["objective_lb"]
        sheet["$(string("A",10))"] = meanFFR
        sheet["$(string("A",11))"] = meanFCR
    end
end
######################start inertia############################
# inertia = 1:0.1:1.3
# column = ["A" "B" "C" "D" "E" "F" "G" "H"]
# filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\inertia\\",Prot_system,".xlsx")
# XLSX.openxlsx(filepath, mode="w") do xf
#     for i = 1:length(inertia)
#         for (n,nw) in data_cont["nw"]
#             for (r,reserves) in nw["reserves"]
#                  reserves["H"] = deepcopy(reserves["H"])*inertia[i]
#             end
#         end
#          resultDC1 = _PMACDC.run_acdcscopf(data_cont, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
#          curtail, maxFFR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
#          sheet = xf[1]
#          cell_no = string(column[i],i)
#          sheet["$(string(column[i],1))"] = data_cont["nw"]["1"]["reserves"]["2"]["H"]
#          sheet["$(string(column[i],2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
#          sheet["$(string(column[i],3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
#          sheet["$(string(column[i],4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
#          sheet["$(string(column[i],5))"] = sum(curtail)
#          sheet["$(string(column[i],6))"] = resultDC1["objective"]
#          sheet["$(string(column[i],7))"] = maxFFR
#          sheet["$(string(column[i],8))"] = resultDC1["objective_lb"]
#         end
#     end
# end
######################end inertia############################

#####################start fuel cost############################
# fuel_cost = 8:1:12
# column = ["A" "B" "C" "D" "E" "F" "G" "H"]
# filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\fuel_cost\\",Prot_system,".xlsx", )
# XLSX.openxlsx(filepath, mode = "w") do xf
#         for i = 1:length(fuel_cost)
#             for (n, nw) in data_cont["nw"]
#                 nw["gen"]["3"]["cost"][3] = fuel_cost[i] * 100
#             end
#             resultDC1 = _PMACDC.run_acdcscopf(data_cont, _PM.DCPPowerModel, gurobi, multinetwork = true; setting = s)
#             curtail, maxFFR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
#             cell_no = string(column[i],i)
#             sheet = xf[1]
#             sheet["$(string(column[i],1))"] = data_cont["nw"]["1"]["reserves"]["2"]["H"]
#             sheet["$(string(column[i],2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
#             sheet["$(string(column[i],3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
#             sheet["$(string(column[i],4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
#             sheet["$(string(column[i],5))"] = sum(curtail)
#             sheet["$(string(column[i],6))"] = resultDC1["objective"]
#             sheet["$(string(column[i],7))"] = maxFFR
#             sheet["$(string(column[i],8))"] = resultDC1["objective_lb"]
#         end
#     end
# end
######################end fuel cost############################


######################start FFR cost############################
# FFR_cost = 64:8:96
# column = ["A" "B" "C" "D" "E" "F" "G" "H"]
# filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\FFR_cost\\",Prot_system,".xlsx")
# XLSX.openxlsx(filepath, mode="w") do xf
#     for i = 1:length(FFR_cost)
#         for (n,nw) in data_cont["nw"]
#             for (r,reserves) in nw["reserves"]
#            reserves["Cf"] = FFR_cost[i]
#             end
#         end
#             resultDC1 = _PMACDC.run_acdcscopf(data_cont, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
#             curtail, maxFFR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
#             cell_no = string(column[i],i)
#             sheet = xf[1]
#             sheet["$(string(column[i],1))"] = data_cont["nw"]["1"]["reserves"]["2"]["H"]
#             sheet["$(string(column[i],2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
#             sheet["$(string(column[i],3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
#             sheet["$(string(column[i],4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
#             sheet["$(string(column[i],5))"] = sum(curtail)
#             sheet["$(string(column[i],6))"] = resultDC1["objective"]
#             sheet["$(string(column[i],7))"] = maxFFR
#             sheet["$(string(column[i],8))"] = resultDC1["objective_lb"]
#         end
# end
# end
######################end FFR cost############################


######################start FCR cost############################
# FCR_cost = [4.24 4.77 5.3 5.83 6.36]
# column = ["A" "B" "C" "D" "E" "F" "G" "H"]
# filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\FCR_cost\\",Prot_system,".xlsx")
# XLSX.openxlsx(filepath, mode="w") do xf
#     for i = 1:length(FCR_cost)
#         for (n,nw) in data_cont["nw"]
#             for (r,reserves) in nw["reserves"]
#                  reserves["Cg"] = FCR_cost[i]
#             end
#         end
#               resultDC1 = _PMACDC.run_acdcscopf(data_cont, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
#               curtail, maxFFR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
#               cell_no = string(column[i],i)
#               sheet = xf[1]
#               sheet["$(string(column[i],1))"] = data_cont["nw"]["1"]["reserves"]["2"]["H"]
#               sheet["$(string(column[i],2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
#               sheet["$(string(column[i],3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
#               sheet["$(string(column[i],4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
#               sheet["$(string(column[i],5))"] = sum(curtail)
#               sheet["$(string(column[i],6))"] = resultDC1["objective"]
#               sheet["$(string(column[i],7))"] = maxFFR
#               sheet["$(string(column[i],8))"] = resultDC1["objective_lb"]
#     end
# end
# end
######################end FCR cost############################

######################start FFR time############################
# FFR_time = [0.1 0.5 1 1.5]
# column = ["A" "B" "C" "D" "E" "F" "G" "H"]
# filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\FFR_time\\",Prot_system,".xlsx")
# XLSX.openxlsx(filepath, mode="w") do xf
#         for i = 1:length(FFR_time)
#             for (n,nw) in data_cont["nw"]
#                 for (r,reserves) in nw["reserves"]
#                     reserves["Tf"] = FFR_time[i]
#                 end
#             end
#              resultDC1 = _PMACDC.run_acdcscopf(data_cont, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
#              curtail, maxFFR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
#              sheet = xf[1]
#              cell_no = string(column[i],i)
#              sheet["$(string(column[i],1))"] = data_cont["nw"]["1"]["reserves"]["2"]["H"]
#              sheet["$(string(column[i],2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
#              sheet["$(string(column[i],3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
#              sheet["$(string(column[i],4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
#              sheet["$(string(column[i],5))"] = sum(curtail)
#              sheet["$(string(column[i],6))"] = resultDC1["objective"]
#              sheet["$(string(column[i],7))"] = maxFFR
#              sheet["$(string(column[i],8))"] = resultDC1["objective_lb"]
#         end
# end
# end
######################end FFR time############################

######################start FCR time############################
# FCR_time = [5  10]
# column = ["A" "B" "C" "D" "E" "F" "G" "H"]
# filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\FCR_time\\",Prot_system,".xlsx")
# XLSX.openxlsx(filepath, mode="w") do xf
#         for i = 1:length(FCR_time)
#             for (n,nw) in data_cont["nw"]
#                 for (r,reserves) in nw["reserves"]
#                      reserves["Tg"] = FCR_time[i]
#                 end
#             end
#          resultDC1 = _PMACDC.run_acdcscopf(data_cont, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
#          curtail, maxFFR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
#          sheet = xf[1]
#                  cell_no = string(column[i],i)
#                  sheet["$(string(column[i],1))"] = data_cont["nw"]["1"]["reserves"]["2"]["H"]
#                  sheet["$(string(column[i],2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
#                  sheet["$(string(column[i],3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
#                  sheet["$(string(column[i],4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
#                  sheet["$(string(column[i],5))"] = sum(curtail)
#                  sheet["$(string(column[i],6))"] = resultDC1["objective"]
#                  sheet["$(string(column[i],7))"] = maxFFR
#                  sheet["$(string(column[i],8))"] = resultDC1["objective_lb"]
#         end
# end
# end
######################end FCR time############################

#####################start Curtailemnt percentage############################
#     curtl = [0.1 0.2 0.3]
#     column = ["A" "B" "C" "D" "E" "F" "G" "H"]
#     filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\Curtailment-copy1\\",Prot_system,".xlsx")
#     XLSX.openxlsx(filepath, mode="w") do xf
#              for i = 1:length(curtl)
#
#                 s["max_curt"] = curtl[i]
#                 resultDC1 = _PMACDC.run_acdcscopf_nocl(data_cont, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
#                 curtail, maxFFR, maxFCR, meanFFR, meanFCR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
#                 sheet = xf[1]
#                 cell_no = string(column[i],i)
#                 display(cell_no)
#                 sheet["$(string(column[i],1))"] = data_cont["nw"]["1"]["reserves"]["2"]["H"]
#                 sheet["$(string(column[i],2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
#                 sheet["$(string(column[i],3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
#                 sheet["$(string(column[i],4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
#                 # sheet["$(string("A",5))"] = resultDC1["solution"]["nw"]["1"]["Cont"]
#                 sheet["$(string(column[i],5))"] = mean(resultDC1["solution"]["nw"]["1"]["Curt"])
#                 sheet["$(string(column[i],6))"] = resultDC1["objective"]
#                 sheet["$(string(column[i],7))"] = maxFFR
#                 sheet["$(string(column[i],8))"] = maxFCR
#                 sheet["$(string(column[i],9))"] = resultDC1["objective_lb"]
#                 sheet["$(string(column[i],10))"] = meanFFR
#                 sheet["$(string(column[i],11))"] = meanFCR
#                 display("i: $i")
#             end
#    end
# end

# year = ["NAT_2025_Generation", "NAT_2030_Generation", "NAT_2035_Generation", "NAT_2040_Generation", "NAT_2045_Generation", "NAT_2050_Generation"]
# yr = 1
# nw_no = 0
# fname = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[1],"\\output.mat")
# vars = matread(fname)
# fname1 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[1],"\\output_MC.mat")
# vars1 = matread(fname1)
# fname2 = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\wind_sample.mat")
# vars2 = matread(fname2)


# function mp_datainputs(data_ip,Total_sample)
#     kk= 1
#     for i = 1:Total_sample
#         sample = Int(round(8760*(1-rand())))
#         for tt = 1:(length(data_sp["branchdc_ne"])+1)
#             display("kk:$kk")
#             display("sample:$sample")
#             data_ip["nw"]["$kk"]["reserves"]["2"]["H"] = vars["Heq"][sample]
#             data_ip["nw"]["$kk"]["gen"]["3"]["cost"][2] = vars1["MC1"][sample]*100
#             rating = deepcopy(data_ip["nw"]["$kk"]["gen"]["1"]["pmax"])
#             data_ip["nw"]["$kk"]["gen"]["1"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
#             data_ip["nw"]["$kk"]["gen"]["2"]["pmax"] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
#             what about load?
#             kk +=1
#         end
#     end
#     return data_ip
# end


################multiperiod function###################check with Hakan
# extradata = mp_datainputs(data_sp,100)
# function mp_datainputs(data_sp,Total_sample)
#     extradata = Dict{String,Any}()
#     extradata["dim"] = 100
#     extradata["gen"] = Dict{String,Any}()
#     extradata["reserves"] = Dict{String,Any}()
#
#     extradata["gen"]["1"] = Dict{String,Any}()
#     extradata["gen"]["2"] = Dict{String,Any}()
#     extradata["gen"]["3"] = Dict{String,Any}()
#     extradata["reserves"]["2"] = Dict{String,Any}()
#
#     dim = Total_sample
#     extradata["gen"]["1"]["pmax"] = Array{Float64,2}(undef, 1, dim)
#     extradata["gen"]["2"]["pmax"] = Array{Float64,2}(undef, 1, dim)
#     extradata["gen"]["3"]["cost"] = Array{Float64,2}(undef, 2, dim)
#     extradata["reserves"]["2"]["H"] = Array{Float64,2}(undef, 1, dim)
#
#         f_index = 1
#         while f_index <= dim
#             sample = Int(round(8760*(1-rand())))
#             rating = deepcopy(data_sp["gen"]["1"]["pmax"])
#             extradata["gen"]["1"]["pmax"][1, f_index] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
#             extradata["gen"]["2"]["pmax"][1, f_index] = vars2["winddata"][sample]/maximum(vars2["winddata"])*rating
#             extradata["gen"]["3"]["cost"][2, f_index] =  vars1["MC1"][sample]*100
#             extradata["reserves"]["2"]["H"][1, f_index] = vars["Heq"][sample]
#             f_index  = f_index  + 1
#         end
#         return extradata
# end
# mn_data = PowerModelsACDC.multinetwork_data(data_sp, extradata, Set{String}(["source_type", "name", "source_version", "per_unit"]))

# fname = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\NAT_Results\\",year[1],"\\output.mat")



############curtailment##############################


# curtail = curtailment(data_cont, base_list)
