
function build_mn_data(file, no_nw)
    mp_data = _PM.parse_file(file)
    return _IM.replicate(mp_data, no_nw, Set{String}(["source_type", "name", "source_version", "per_unit"]))
end

function multi_network(file, no_nw)
    data1 = build_mn_data(file, no_nw)
    _PMACDC.process_additional_data!(data1)
    return data1
end

# function create_contingency(data_ip, st_nw, end_nw)
#     br_no = 1
#     for n = st_nw:end_nw
#         # display("n:$n")
#         data_ip["nw"]["$n"]["branchdc_ne"]["$br_no"]["rateA"] = 0
#         # display("br_no:$br_no")
#         br_no += 1
#     end
#     return data_ip
# end

function display_keyindictionary(dict, key1, key2)
    for (n, nw) in dict["solution"]["nw"]
    if parse(Int64,n) == 1
        for (b,branch) in nw["branchdc_ne"]
            display("br: $b: $(branch[key1])")
        end
        for (c,conv) in nw["convdc_ne"]
            display("cv: $c: $(conv[key1])")
        end
    end
    end
    display("################reserves################")
    for (n, nw) in dict["solution"]["nw"]
         display("Pgg:n$n $(nw["reserves"]["2"]["Pgg"])")
    end
    for (n, nw) in dict["solution"]["nw"]
     display("Pff:n$n  $(nw["reserves"]["2"]["Pff"])")
    end
    display("################interval################")
    for (n, nw) in dict["solution"]["nw"]
    display("z1:n$n $(nw["reserves"]["2"]["z1"]) z2: $(nw["reserves"]["2"]["z2"]) z3: $(nw["reserves"]["2"]["z3"]) z4: $(nw["reserves"]["2"]["z4"])  z5: $(nw["reserves"]["2"]["z5"])")
    end
    display("################gen################")
    for (n, nw) in dict["solution"]["nw"]
    display("Pg1:n$n $(nw["gen"]["1"]["pg"])  Pg2: $(nw["gen"]["2"]["pg"])  Pg3: $(nw["gen"]["3"]["pg"])")
    end
    display("################branch################")
    for (n, nw) in dict["solution"]["nw"]
    # display("b1:n$n $(nw["branchdc_ne"]["1"]["pf"])  b2: $(nw["branchdc_ne"]["2"]["pf"]) b3: $(nw["branchdc_ne"]["3"]["pf"]) b4: $(nw["branchdc_ne"]["4"]["pf"])")
        display("n$n:b1: $(nw["branchdc_ne"]["1"]["pf"])  b2: $(nw["branchdc_ne"]["2"]["pf"]) b3: $(nw["branchdc_ne"]["3"]["pf"]) b4: $(nw["branchdc_ne"]["4"]["pf"]) ")
        # display("n$n:b5: $(nw["branchdc_ne"]["5"]["pf"])  b6: $(nw["branchdc_ne"]["6"]["pf"])")
        # b7: $(nw["branchdc_ne"]["7"]["pf"]) b8: $(nw["branchdc_ne"]["8"]["pf"]) )
        #display("n$n:b9: $(nw["branchdc_ne"]["9"]["pf"])  b10: $(nw["branchdc_ne"]["10"]["pf"]) b11: $(nw["branchdc_ne"]["11"]["pf"]) b12: $(nw["branchdc_ne"]["12"]["pf"]) ")
    end
    display("################Power deviation################")
    display("Phvdc,open: $(dict["solution"]["nw"]["2"]["reserves"]["2"]["Phvdcoaux"])")
    for (n, nw) in dict["solution"]["nw"]
        display("Phvdc,open:n$n $(nw["reserves"]["2"]["Phvdcoaux"])")
         display("Phvdc,close:n$n $(nw["reserves"]["2"]["Phvdccaux"])")
    end

    display("$(dict["solution"]["nw"]["1"]["Inv_cost"])")
    display("$(dict["solution"]["nw"]["1"]["Reserves"])")
    display("$(dict["solution"]["nw"]["1"]["Gen_cost"])")
    display("$(dict["solution"]["nw"]["1"]["Cont"])")
    display("$(dict["objective"])")
end

function display_keyindictionary_OPF(dict, key1, key2)
    display("################reserves################")
    for (n, nw) in dict["solution"]["nw"]
         display("Pgg:n$n $(nw["reserves"]["2"]["Pgg"])")
    end
    for (n, nw) in dict["solution"]["nw"]
     display("Pff:n$n  $(nw["reserves"]["2"]["Pff"])")
    end

    display("################interval################")
    for (n, nw) in dict["solution"]["nw"]
    display("z1:n$n $(nw["reserves"]["2"]["z1"]) z2: $(nw["reserves"]["2"]["z2"]) z3: $(nw["reserves"]["2"]["z3"]) z4: $(nw["reserves"]["2"]["z4"])  z5: $(nw["reserves"]["2"]["z5"])")
    end
    display("################gen################")
    for (n, nw) in dict["solution"]["nw"]
    display("Pg1:n$n $(nw["gen"]["1"]["pg"])  Pg2: $(nw["gen"]["2"]["pg"])  Pg3: $(nw["gen"]["3"]["pg"])")
    end
    display("################branch################")
    for (n, nw) in dict["solution"]["nw"]
    # display("b1:n$n $(nw["branchdc_ne"]["1"]["pf"])  b2: $(nw["branchdc_ne"]["2"]["pf"]) b3: $(nw["branchdc_ne"]["3"]["pf"]) b4: $(nw["branchdc_ne"]["4"]["pf"])")
        display("n$n:b1: $(nw["branchdc"]["1"]["pf"])  b2: $(nw["branchdc"]["2"]["pf"]) b3: $(nw["branchdc"]["3"]["pf"]) b4: $(nw["branchdc"]["4"]["pf"]) ")
        # display("n$n:b5: $(nw["branchdc_ne"]["5"]["pf"])  b6: $(nw["branchdc_ne"]["6"]["pf"])")
        # b7: $(nw["branchdc_ne"]["7"]["pf"]) b8: $(nw["branchdc_ne"]["8"]["pf"]) )
        #display("n$n:b9: $(nw["branchdc_ne"]["9"]["pf"])  b10: $(nw["branchdc_ne"]["10"]["pf"]) b11: $(nw["branchdc_ne"]["11"]["pf"]) b12: $(nw["branchdc_ne"]["12"]["pf"]) ")
    end
    display("################Power deviation################")
    display("Phvdc,open: $(dict["solution"]["nw"]["2"]["reserves"]["2"]["Phvdcoaux"])")
    for (n, nw) in dict["solution"]["nw"]
        display("Phvdc,open:n$n $(nw["reserves"]["2"]["Phvdcoaux"])")
        display("Phvdc,close:n$n $(nw["reserves"]["2"]["Phvdccaux"])")
    end

    display("$(dict["solution"]["nw"]["1"]["FCR_Reserves"])")
    display("$(dict["solution"]["nw"]["1"]["FFR_Reserves"])")
    display("$(dict["solution"]["nw"]["1"]["Gen_cost"])")
    # display("$(dict["solution"]["nw"]["1"]["Cont"])")
    display("$(dict["objective"])")
end

function Protectionsystemcost(data, PS, no_nw)
    for (n,nw) in data["nw"]
        display("nw:$n")
        for (c,conv) in nw["convdc_ne"]
            if PS == "NS_CB"
                if conv["Pacmax"] == 24
                conv["cost"] = conv["cost"] + 24/no_nw #line breaker are ignored
                elseif conv["Pacmax"] == 12
                conv["cost"] = conv["cost"] + 24*0.5/no_nw #line breaker are ignored
                end
            elseif PS == "NS_FB"
                if conv["Pacmax"] == 24
                    conv["cost"] = conv["cost"] + (193-150)/no_nw
                elseif conv["Pacmax"] == 12
                    conv["cost"] = conv["cost"] + (193-150)*0.5/no_nw
                end
            end
        end
        for (b,branch) in nw["branchdc_ne"]
            if string(PS) == "FS_HDCCB"
                if branch["rateA"] == 24
                    branch["cost"] = branch["cost"] + 47/no_nw
                    display("br_cost:$(branch["cost"])")
                elseif branch["rateA"] == 12
                    branch["cost"] = branch["cost"] + 47*0.5/no_nw
                end
            elseif PS == "FS_MDCCB"
                if branch["rateA"] == 24
                    branch["cost"] = branch["cost"] + 39/no_nw
                elseif branch["rateA"] == 12
                    branch["cost"] = branch["cost"] + 39*0.5/no_nw
                end
            elseif PS == "NS_FB"
                if branch["rateA"] == 24
                    branch["cost"] = branch["cost"] + 6/no_nw
                elseif branch["rateA"] == 12
                    branch["cost"] = branch["cost"] + 6*0.5/no_nw
                end
            end
        end
    end
    return data
end




#
# for (n,nw) in data_cont["nw"]
#     for (c,conv) in nw["convdc_ne"]
#         display(conv["cost"])
#     end
# end
#
# for (n,nw) in data_cont["nw"]
#     for (b,branch) in nw["branchdc_ne"]
#         display("$b: $(branch["cost"])")
#     end
# end

# resultDC = _PMACDC.run_tnepopf(data, _PM.DCPPowerModel, gurobi, setting = s)
# sum(br["isbuilt"] for (b,br) in resultDC["solution"]["branchdc_ne"])
# sum(br["isbuilt"] for (b,br) in resultDC["solution"]["convdc_ne"])
#
# _PMACDC.display_results_tnep(resultDC)


function curtailment(data_cont, base_list, resultDC1, curtailed_gen)
    curt = Any[]
     kkk=1
     for tt = 1:length(base_list)
             kkk= base_list[tt]
             available = sum(data_cont["nw"]["$kkk"]["gen"]["$i"]["pmax"] for i in curtailed_gen)
             generated = sum(resultDC1["solution"]["nw"]["$kkk"]["gen"]["$i"]["pg"] for i in curtailed_gen)
             # display(generated)
             # display("nw$tt: available:$available")
             # display("nw$tt: generated:$generated")
            curtailment = available - generated
            push!(curt, curtailment)
    end

    formax =[]
     for (n, nw) in resultDC1["solution"]["nw"]
            push!(formax, nw["reserves"]["2"]["Pff"])
    end

     return curt, maximum(formax)
end
