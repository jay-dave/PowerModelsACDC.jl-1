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

Total_sample = 1  # sample per year
total_yr = 1# the years in horizon, data coming from excels

Prot_system = "FS_HDCCB"
# Prot_system_coll = ["FS_HDCCB", "NS_CB", "Permanentloss"]
curtailed_gen = [1] #geneartor numbers # change also constraint max(), generating power,file name
syncarea = 2
max_curt = 0
# for proti = 1:3
#     Prot_system = Prot_system_coll[proti]
file = "./test/data/4bus_OPF_PLdim.m"
data_sp = _PM.parse_file(file)
_PMACDC.process_additional_data!(data_sp)

include("bkgrnd_cal.jl")
gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer, "Presolve" => -1)

    no_nw = 2 * Total_sample*total_yr
    data_mp = multi_network(file, no_nw)
    # year = ["NAT_2050_Generation"]
    yr = 1

    data_cont, Cont_list, base_list = mp_contignecy_nocl_sensitivity(deepcopy(data_mp), Total_sample*total_yr, 1)
    year_base = year_base_networks(Total_sample, total_yr, base_list)

    conv_rate = Int(data_cont["nw"]["1"]["convdc"]["1"]["Pacmax"]*100)
    Clearingtime = [0.15 0.3 0.45 0.6]
    column = ["A" "B" "C" "D" "E" "F" "G" "H"]
    filepath = string("C:\\Users\\djaykuma\\OneDrive - Energyville\\Freq_TNEP_paper\\MATLAB\\plots\\OPF\\4bus\\sensitivity\\1.0\\",conv_rate,"_",Prot_system,".xlsx")
    XLSX.openxlsx(filepath, mode="w") do xf
        for i = 1:length(Clearingtime)
            for (n,nw) in data_cont["nw"]
                for (r,reserves) in nw["reserves"]
                     reserves["Tcl"] = Clearingtime[i]
                end
            end
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
    @assert ( s["FSprotection"] == true && (Prot_system == "FS_HDCCB" || Prot_system == "FS_MDCCB") ) || (s["NSprotection"] == true && (Prot_system == "NS_CB" || Prot_system == "NS_FB"))|| (Prot_system == "Permanentloss" && s["NSprotection"] == false && s["FSprotection"] == false)
     resultDC1 = _PMACDC.run_acdcscopf_sensitivity(data_cont, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
     # curtail, maxFFR, maxFCR, meanFFR, meanFCR = curtailment(data_cont, base_list, resultDC1, curtailed_gen)
     display_keyindictionary_OPF_PLdim(resultDC1, "isbuilt", "Pgg")
     sheet = xf[1]
     cell_no = string(column[i],i)
     sheet["$(string(column[i],1))"] = data_cont["nw"]["1"]["reserves"]["2"]["Tcl"]
     sheet["$(string(column[i],2))"] = resultDC1["solution"]["nw"]["1"]["FFR_Reserves"]
     sheet["$(string(column[i],3))"] = resultDC1["solution"]["nw"]["1"]["FCR_Reserves"]
     sheet["$(string(column[i],4))"] = resultDC1["solution"]["nw"]["1"]["Gen_cost"]
     # sheet["$(string("A",5))"] = resultDC1["solution"]["nw"]["1"]["Cont"]
     sheet["$(string(column[i],5))"] = mean(resultDC1["solution"]["nw"]["1"]["Curt"])
     sheet["$(string(column[i],6))"] = resultDC1["objective"]
     sheet["$(string(column[i],7))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["z1"]
     sheet["$(string(column[i],8))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["z2"]
     sheet["$(string(column[i],9))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["z3"]
     sheet["$(string(column[i],10))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["z4"]
     sheet["$(string(column[i],11))"] =  resultDC1["solution"]["nw"]["1"]["branchdc"]["1"]["pf"]
     sheet["$(string(column[i],12))"] =  resultDC1["solution"]["nw"]["2"]["branchdc"]["1"]["pf"]

     sheet["$(string(column[i],13))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k11_dup"]
     sheet["$(string(column[i],14))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k12_dup"]
     sheet["$(string(column[i],15))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k21_dup"]
     sheet["$(string(column[i],16))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k22_dup"]
     sheet["$(string(column[i],17))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k23_dup"]
     sheet["$(string(column[i],18))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k31"]
     sheet["$(string(column[i],19))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k32"]
     sheet["$(string(column[i],20))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k33"]
     sheet["$(string(column[i],21))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k31_dup"]
     sheet["$(string(column[i],22))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k32_dup"]
     sheet["$(string(column[i],23))"] = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["k43_dup"]

     if round(Int64,resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["z3"]) == 1
         t = nadir_time_t3(resultDC1, data_cont)
         display("t3")
     elseif round(Int64,resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["z4"]) == 1
         t = nadir_time_t4(resultDC1, data_cont)
         display("t4")
     else
         t = 500
     end
     sheet["$(string(column[i],24))"] =  t
    end
end
# end

function nadir_time_t3(resultDC1, data_cont)
    Phvdcoaux = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["Phvdcoaux"]
    Phvdccaux = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["Phvdccaux"]
    display("Phvdcoaux:$Phvdcoaux")
    display("Phvdccaux:$Phvdccaux")
    Pg = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["Pgg"]/data_cont["nw"]["1"]["load"]["1"]["pd"]
    Pf = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["Pff"]/data_cont["nw"]["1"]["load"]["1"]["pd"]
    Tcl = data_cont["nw"]["1"]["reserves"]["2"]["Tcl"]
    Td = data_cont["nw"]["1"]["reserves"]["2"]["Td"]
    Tg = data_cont["nw"]["1"]["reserves"]["2"]["Tg"]
    Tf = data_cont["nw"]["1"]["reserves"]["2"]["Tf"]
    display("Pg:$Pg")
    display("Pf:$Pf")
    display(data_cont["nw"]["1"]["load"]["1"]["pd"])
    t3 = (Phvdcoaux  - Pf +  Phvdccaux*Tcl/Td)/((Pg/Tg) + (Phvdccaux/Td))
    display("t3:$t3")
    return t3
end

function nadir_time_t4(resultDC1, data_cont)
    Phvdcoaux = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["Phvdcoaux"]
    Phvdccaux = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["Phvdccaux"]
    display("Phvdcoaux:$Phvdcoaux")
    display("Phvdccaux:$Phvdccaux")
    Pg = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["Pgg"]/data_cont["nw"]["1"]["load"]["1"]["pd"]
    Pf = resultDC1["solution"]["nw"]["2"]["reserves"]["2"]["Pff"]/data_cont["nw"]["1"]["load"]["1"]["pd"]
    Tcl = data_cont["nw"]["1"]["reserves"]["2"]["Tcl"]
    Td = data_cont["nw"]["1"]["reserves"]["2"]["Td"]
    Tg = data_cont["nw"]["1"]["reserves"]["2"]["Tg"]
    Tf = data_cont["nw"]["1"]["reserves"]["2"]["Tf"]
    display("Pg:$Pg")
    display("Pf:$Pf")
    display(data_cont["nw"]["1"]["load"]["1"]["pd"])
    t4 = (Phvdcoaux -  Phvdccaux - Pf)*Tg/Pg
    display("t4:$t4")
    return t4
end
