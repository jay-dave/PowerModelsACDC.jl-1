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

Total_sample = 50  # sample per year
total_yr = 6# the years in horizon, data coming from excels
period = "multi" # single or multi

Prot_system = "Permanentloss"
curtailed_gen = [1] #geneartor numbers # change also constraint max(), generating power,file name
syncarea = 2
max_curt = 0
@load "scenario_500.jld2"

    file = "./test/data/4bus_OPF_PLdim.m"
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

    data_ps = mp_datainputs_nocl_PLdim(deepcopy(data_mp), Total_sample, year, year_num, scenario_500, file)
    data_cont, Cont_list, base_list = mp_contignecy_nocl(deepcopy(data_ps), Total_sample*total_yr, 1)
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
        filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\injection\\wthFCRlim\\",conv_rate,"MW\\",Prot_system,"_sPLdim.xlsx")
    elseif occursin("6bus", file)
        filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\injection\\wthFCRlim\\",conv_rate,"MW\\",Prot_system,"_sPLdim.xlsx")
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

    resultDC1 = _PMACDC.run_acdcscopf_nocl_PLdim(data_cont, _PM.DCPPowerModel, gurobi, multinetwork = true;  setting = s)
    display_keyindictionary_OPF_PLdim(resultDC1, "isbuilt", "Pgg")
    # display(curtailed_gen)
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


FCR_reserve_hr_2025 = Any[]; FCR_reserve_hr_2030 = Any[]; FCR_reserve_hr_2035 = Any[]; FCR_reserve_hr_2040 = Any[]; FCR_reserve_hr_2045 = Any[]; FCR_reserve_hr_2050 = Any[]
FFR_reserve_hr_2025 = Any[]; FFR_reserve_hr_2030 = Any[]; FFR_reserve_hr_2035 = Any[]; FFR_reserve_hr_2040 = Any[]; FFR_reserve_hr_2045 = Any[]; FFR_reserve_hr_2050 = Any[]
Inertia_2025 = Any[]; Inertia_2030 = Any[]; Inertia_2035 = Any[]; Inertia_2040 = Any[]; Inertia_2045 = Any[]; Inertia_2050 = Any[]



for b in year_base[1]
     push!(Inertia_2025, data_cont["nw"]["$b"]["reserves"]["2"]["H"])
     push!(FFR_reserve_hr_2025, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pff"])
     push!(FCR_reserve_hr_2025, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pgg"])
end

for b in year_base[2]
     push!(Inertia_2030, data_cont["nw"]["$b"]["reserves"]["2"]["H"])
     push!(FFR_reserve_hr_2030, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pff"])
     push!(FCR_reserve_hr_2030, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pgg"])
end

for b in year_base[3]
     push!(Inertia_2035, data_cont["nw"]["$b"]["reserves"]["2"]["H"])
     push!(FFR_reserve_hr_2035, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pff"])
     push!(FCR_reserve_hr_2035, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pgg"])
end
for b in year_base[4]
     push!(Inertia_2040, data_cont["nw"]["$b"]["reserves"]["2"]["H"])
     push!(FFR_reserve_hr_2040, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pff"])
     push!(FCR_reserve_hr_2040, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pgg"])
end
for b in year_base[5]
     push!(Inertia_2045, data_cont["nw"]["$b"]["reserves"]["2"]["H"])
     push!(FFR_reserve_hr_2045, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pff"])
     push!(FCR_reserve_hr_2045, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pgg"])
end
for b in year_base[6]
     push!(Inertia_2050, data_cont["nw"]["$b"]["reserves"]["2"]["H"])
     push!(FFR_reserve_hr_2050, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pff"])
     push!(FCR_reserve_hr_2050, resultDC1["solution"]["nw"]["$(b+1)"]["reserves"]["2"]["Pgg"])
end
