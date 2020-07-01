using PowerModelsACDC, PowerModels, Ipopt, Juniper, JuMP, Cbc, Gurobi

function converter_cost(data)
    for(c,conv) in data["convdc_ne"]
        conv["cost"] = conv["Pacmax"]*0.083 *100+ 28
    end
end

function converter_parameters_rxb(data)
for (c,conv) in data["convdc_ne"]
    bus = conv["busac_i"]
    base_kV = data["bus"]["$bus"]["base_kv"]
    base_S = sqrt((100*conv["Pacmax"])^2+(100*conv["Qacmax"])^2) #base MVA = 100
    base_Z = base_kV^2/base_S # L-L votlage/3 phase power
    base_Y= 1/base_Z
    conv["xtf"] = 0.10*100/base_S #new X =old X *(100MVA/old Sbase)
    # display(conv["xtf"])
    # display(base_Z)
    conv["rtf"] = conv["xtf"]/100
    conv["bf"] = 0.08*base_S/100
    conv["xc"] = 0.07*100/base_S #new X =old X *(100MVA/old Zbase)
    # display(conv["xc"])
    # display(base_Z)
    conv["rc"] = conv["xc"]/100 #new X =old X *(100MVA/old Zbase)
    rtf = conv["rtf"]
    xtf = conv["xtf"]
    bf = conv["bf"]
    Pmax = conv["Pacmax"]
    Pmin =  conv["Pacmin"]
    Qmax = conv["Qacmax"]
    Qmin =  conv["Qacmin"]

    conv["Imax"] = sqrt(Pmax^2+Qmax^2)
    xc = conv["xc"]
    rc = conv["rc"]
    Imax = conv["Imax"]

end
end

## start of each test case run
casename = "case9"
bt = 100 ## constraint tightening setting 95, 90, 85, 80

file = "./test/data/tnep/PSCC test cases/$casename.m"
data1 = PowerModels.parse_file(file)
PowerModelsACDC.process_additional_data!(data1)
# PowerModelsACDCInv.process_additional_data!(data1)
data = deepcopy(data1)

#increase load and generation by 3 times (except 6 and 24 bus)
for i = 1: length(keys(data["load"]))
    data["load"]["$i"]["pd"] = 3* data1["load"]["$i"]["pd"]
    data["load"]["$i"]["qd"] = 3* data1["load"]["$i"]["qd"]
end
for j = 1: length(keys(data["gen"]))
    data["gen"]["$j"]["pmax"] = 3*data1["gen"]["$j"]["pmax"]
    data["gen"]["$j"]["qmax"] = 3*data1["gen"]["$j"]["qmax"]
    data["gen"]["$j"]["qmin"] = 3*data1["gen"]["$j"]["qmin"]
end
#constraint tightening
for (b,branch) in data["branch"]
    branch["rate_a"] = bt/100* branch["rate_a"]
end
for (b,branchdc) in data["branchdc_ne"]
    branchdc["rateA"] = bt/100* branchdc["rateA"]
end

ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=1)
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, tol=1e-4)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer)
juniper = JuMP.with_optimizer(Juniper.Optimizer, mip_solver=cbc_solver, nl_solver = ipopt)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false, "process_data_internally" => false)

converter_parameters_rxb(data)
# converter_cost(data)      # only to use with 6 and 24 bus systems
 data_pf1 = deepcopy(data)

##
resultDC = run_tnepopf(data, DCPPowerModel, gurobi, setting = s)
resultDC["built_cv"], resultDC["built_br"] = PowerModelsACDC.display_results_tnep(resultDC)

resultSOCBF = run_tnepopf_bf(data, SOCBFPowerModel, gurobi, setting = s)
resultSOCBF["built_cv"], resultSOCBF["built_br"] = PowerModelsACDC.display_results_tnep(resultSOCBF)

resultSOCWR = run_tnepopf(data, SOCWRPowerModel, gurobi, setting = s)
resultSOCWR["built_cv"], resultSOCWR["built_br"] = PowerModelsACDC.display_results_tnep(resultSOCWR)

resultQC     =  run_tnepopf(data, QCRMPowerModel, gurobi; setting = s)
resultQC["built_cv"], resultQC["built_br"] = PowerModelsACDC.display_results_tnep(resultQC)

resultAC_juni     =  run_tnepopf(data, ACPPowerModel, juniper; setting = s)
resultAC_juni["built_cv"], resultAC_juni["built_br"] = PowerModelsACDC.display_results_tnep(resultAC_juni)

resultLPAC     =  run_tnepopf(data, LPACCPowerModel, gurobi; setting = s)
resultLPAC["built_cv"], resultLPAC["built_br"] = PowerModelsACDC.display_results_tnep(resultLPAC)
