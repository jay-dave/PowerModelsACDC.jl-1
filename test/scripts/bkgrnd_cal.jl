
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
         ("Pgg:n$n $(nw["reserves"]["2"]["Pgg"])")
    end
    for (n, nw) in dict["solution"]["nw"]
     ("Pff:n$n  $(nw["reserves"]["2"]["Pff"])")
    end
    ("################interval################")
    for (n, nw) in dict["solution"]["nw"]
    ("z1:n$n $(nw["reserves"]["2"]["z1"]) z2: $(nw["reserves"]["2"]["z2"]) z3: $(nw["reserves"]["2"]["z3"]) z4: $(nw["reserves"]["2"]["z4"])  z5: $(nw["reserves"]["2"]["z5"])")
    end
    ("################gen################")
    for (n, nw) in dict["solution"]["nw"]
    ("Pg1:n$n $(nw["gen"]["1"]["pg"])  Pg2: $(nw["gen"]["2"]["pg"])  Pg3: $(nw["gen"]["3"]["pg"])")
    end
    ("################branch################")
    for (n, nw) in dict["solution"]["nw"]
    ("b1:n$n $(nw["branchdc_ne"]["1"]["pf"])  b2: $(nw["branchdc_ne"]["2"]["pf"]) b3: $(nw["branchdc_ne"]["3"]["pf"]) b4: $(nw["branchdc_ne"]["4"]["pf"])  b5: $(nw["branchdc_ne"]["5"]["pf"])  b6: $(nw["branchdc_ne"]["6"]["pf"]) b7: $(nw["branchdc_ne"]["7"]["pf"]) b8: $(nw["branchdc_ne"]["8"]["pf"])")
    ("b9:n$n $(nw["branchdc_ne"]["9"]["pf"])  b10: $(nw["branchdc_ne"]["10"]["pf"]) b11: $(nw["branchdc_ne"]["11"]["pf"]) b12: $(nw["branchdc_ne"]["12"]["pf"])")
        # n$n:b7: $(nw["branchdc_ne"]["7"]["pf"]) b8: $(nw["branchdc_ne"]["8"]["pf"])")
        # #display("n$n:b9: $(nw["branchdc_ne"]["9"]["pf"])  b10: $(nw["branchdc_ne"]["10"]["pf"]) b11: $(nw["branchdc_ne"]["11"]["pf"]) b12: $(nw["branchdc_ne"]["12"]["pf"]) ")
    end
    ("################Power deviation################")
    ("Phvdc,open: $(dict["solution"]["nw"]["2"]["reserves"]["2"]["Phvdcoaux"])")
    for (n, nw) in dict["solution"]["nw"]
        ("Phvdc,open:n$n $(nw["reserves"]["2"]["Phvdcoaux"])")
         ("Phvdc,close:n$n $(nw["reserves"]["2"]["Phvdccaux"])")
    end

    display("Invcost: $(dict["solution"]["nw"]["1"]["Inv_cost"])")
    display("FCRcost: $(dict["solution"]["nw"]["1"]["FCR_Reserves"])")
    display("FFRcost: $(dict["solution"]["nw"]["1"]["FFR_Reserves"])")
    display("Gencost: $(dict["solution"]["nw"]["1"]["Gen_cost"])")
    display("Objective: $(dict["objective"])")
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
function Protectionsystemcost_4bus(data, PS, no_nw)
    #no cost of permanent cost, ac side protection
    for (n,nw) in data["nw"]
        display("nw:$n")
        if PS == "FS_HDCCB"
                  nw["convdc_ne"]["3"]["cost"] = 274.13/no_nw; nw["convdc_ne"]["4"]["cost"] = 274.13/no_nw; nw["convdc_ne"]["2"]["cost"] = 360.32/no_nw; nw["convdc_ne"]["1"]["cost"] = 360.32/no_nw
                  # nw["convdc_ne"]["5"]["cost"] = 143.56/no_nw; nw["convdc_ne"]["6"]["cost"] = 143.56/no_nw; nw["convdc_ne"]["7"]["cost"] = 189.27/no_nw; nw["convdc_ne"]["8"]["cost"] = 189.27/no_nw

                  # nw["branchdc_ne"]["1"]["cost"] = 448.91/no_nw;
                  # nw["branchdc_ne"]["2"]["cost"] = 1288.91/no_nw; nw["branchdc_ne"]["3"]["cost"] = 658.91/no_nw; nw["branchdc_ne"]["4"]["cost"] = 1288.91/no_nw
                  # nw["branchdc_ne"]["5"]["cost"] = 448.91/no_nw; nw["branchdc_ne"]["6"]["cost"] = 1491.7/no_nw;
                  # nw["branchdc_ne"]["7"]["cost"] = 448.91*0.5/no_nw;
                  # nw["branchdc_ne"]["8"]["cost"] = 1288.91*0.5/no_nw; nw["branchdc_ne"]["9"]["cost"] = 658.91*0.5/no_nw; nw["branchdc_ne"]["10"]["cost"] = 1288.91*0.5/no_nw
                  # nw["branchdc_ne"]["11"]["cost"] = 448.91*0.5/no_nw; nw["branchdc_ne"]["12"]["cost"] = 1491.7*0.5/no_nw;
                  #
                  nw["branchdc_ne"]["1"]["cost"] = 232.36/no_nw;
                  nw["branchdc_ne"]["2"]["cost"] = 652.36/no_nw; nw["branchdc_ne"]["3"]["cost"] = 337.36/no_nw; nw["branchdc_ne"]["4"]["cost"] = 652.36/no_nw;
                  nw["branchdc_ne"]["5"]["cost"] = 232.36/no_nw; nw["branchdc_ne"]["6"]["cost"] = 752.14/no_nw;
                  nw["branchdc_ne"]["7"]["cost"] = 232.36*0.5/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 652.36*0.5/no_nw; nw["branchdc_ne"]["9"]["cost"] = 337.36*0.5/no_nw; nw["branchdc_ne"]["10"]["cost"] = 652.36*0.5/no_nw;
                  nw["branchdc_ne"]["11"]["cost"] = 232.36*0.5/no_nw; nw["branchdc_ne"]["12"]["cost"] = 752.14*0.5/no_nw;

        elseif PS == "FS_MDCCB"
                  nw["convdc_ne"]["3"]["cost"] = 269.4/no_nw; nw["convdc_ne"]["4"]["cost"] = 269.4/no_nw; nw["convdc_ne"]["2"]["cost"] = 356.55/no_nw; nw["convdc_ne"]["1"]["cost"] = 356.55/no_nw
                  # nw["convdc_ne"]["5"]["cost"] = 140.32/no_nw; nw["convdc_ne"]["6"]["cost"] = 140.32/no_nw; nw["convdc_ne"]["7"]["cost"] = 188/no_nw; nw["convdc_ne"]["8"]["cost"] = 188/no_nw

                  # nw["branchdc_ne"]["1"]["cost"] = 440.40/no_nw;
                  # nw["branchdc_ne"]["2"]["cost"] = 1280.41/no_nw; nw["branchdc_ne"]["3"]["cost"] = 650.40/no_nw; nw["branchdc_ne"]["4"]["cost"] = 1280.41/no_nw
                  # nw["branchdc_ne"]["5"]["cost"] = 440.40/no_nw; nw["branchdc_ne"]["6"]["cost"] = 1482.24/no_nw;
                  # nw["branchdc_ne"]["7"]["cost"] = 440.40*0.5/no_nw;
                  # nw["branchdc_ne"]["8"]["cost"] = 1280.41*0.5/no_nw; nw["branchdc_ne"]["9"]["cost"] = 650.40*0.5/no_nw; nw["branchdc_ne"]["10"]["cost"] = 1280.41*0.5/no_nw
                  # nw["branchdc_ne"]["11"]["cost"] = 440.40*0.5/no_nw; nw["branchdc_ne"]["12"]["cost"] = 1482.24*0.5/no_nw;

                  nw["branchdc_ne"]["1"]["cost"] = 227.84/no_nw;
                  nw["branchdc_ne"]["2"]["cost"] = 647.84/no_nw; nw["branchdc_ne"]["3"]["cost"] = 332.84/no_nw; nw["branchdc_ne"]["4"]["cost"] = 647.84/no_nw
                  nw["branchdc_ne"]["5"]["cost"] = 227.84/no_nw; nw["branchdc_ne"]["6"]["cost"] = 745.66/no_nw;
                  nw["branchdc_ne"]["7"]["cost"] = 227.84*0.5/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 647.84*0.5/no_nw; nw["branchdc_ne"]["9"]["cost"] = 332.84*0.5/no_nw; nw["branchdc_ne"]["10"]["cost"] = 647.84*0.5/no_nw
                  nw["branchdc_ne"]["11"]["cost"] = 227.84*0.5/no_nw; nw["branchdc_ne"]["12"]["cost"] = 745.66*0.5/no_nw;

        elseif PS == "NS_CB"
                  nw["convdc_ne"]["3"]["cost"] = 268.7/no_nw; nw["convdc_ne"]["4"]["cost"] = 268.7/no_nw; nw["convdc_ne"]["2"]["cost"] = 352.21/no_nw; nw["convdc_ne"]["1"]["cost"] = 352.21/no_nw
                  # nw["convdc_ne"]["5"]["cost"] = 140.41/no_nw; nw["convdc_ne"]["6"]["cost"] = 140.41/no_nw; nw["convdc_ne"]["7"]["cost"] = 185.43/no_nw; nw["convdc_ne"]["8"]["cost"] = 185.43/no_nw

                  # nw["branchdc_ne"]["1"]["cost"] = 440.40/no_nw;
                  # nw["branchdc_ne"]["2"]["cost"] = 1280.41/no_nw; nw["branchdc_ne"]["3"]["cost"] = 650.40/no_nw; nw["branchdc_ne"]["4"]["cost"] = 1280.41/no_nw
                  # nw["branchdc_ne"]["5"]["cost"] = 440.40/no_nw; nw["branchdc_ne"]["6"]["cost"] = 1482.24/no_nw;
                  # nw["branchdc_ne"]["7"]["cost"] = 440.40*0.5/no_nw;
                  # nw["branchdc_ne"]["8"]["cost"] = 1280.41*0.5/no_nw; nw["branchdc_ne"]["9"]["cost"] = 650.40*0.5/no_nw; nw["branchdc_ne"]["10"]["cost"] = 1280.41*0.5/no_nw
                  # nw["branchdc_ne"]["11"]["cost"] = 440.40*0.5/no_nw; nw["branchdc_ne"]["12"]["cost"] = 1482.2*0.54/no_nw;
                  nw["branchdc_ne"]["1"]["cost"] = 227.84/no_nw;
                  nw["branchdc_ne"]["2"]["cost"] = 647.84/no_nw; nw["branchdc_ne"]["3"]["cost"] = 332.84/no_nw; nw["branchdc_ne"]["4"]["cost"] = 647.84/no_nw
                  nw["branchdc_ne"]["5"]["cost"] = 227.84/no_nw; nw["branchdc_ne"]["6"]["cost"] = 745.66/no_nw;
                  nw["branchdc_ne"]["7"]["cost"] = 227.84*0.5/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 647.84*0.5/no_nw; nw["branchdc_ne"]["9"]["cost"] = 332.84*0.5/no_nw; nw["branchdc_ne"]["10"]["cost"] = 647.84*0.5/no_nw
                  nw["branchdc_ne"]["11"]["cost"] = 227.84*0.5/no_nw; nw["branchdc_ne"]["12"]["cost"] = 745.66*0.5/no_nw;

        elseif PS == "NS_FB"
                  nw["convdc_ne"]["3"]["cost"] = 306.99/no_nw; nw["convdc_ne"]["4"]["cost"] = 306.99/no_nw; nw["convdc_ne"]["2"]["cost"] = 399.08/no_nw; nw["convdc_ne"]["1"]["cost"] = 399.08/no_nw
                  # nw["convdc_ne"]["5"]["cost"] = 176.91/no_nw; nw["convdc_ne"]["6"]["cost"] = 176.91/no_nw; nw["convdc_ne"]["7"]["cost"] = 229.98/no_nw; nw["convdc_ne"]["8"]["cost"] = 229.98/no_nw

                  # nw["branchdc_ne"]["1"]["cost"] = 422.92/no_nw;
                  # nw["branchdc_ne"]["2"]["cost"] = 1262.93/no_nw; nw["branchdc_ne"]["3"]["cost"] = 632.92/no_nw; nw["branchdc_ne"]["4"]["cost"] = 1262.93/no_nw
                  # nw["branchdc_ne"]["5"]["cost"] = 422.92/no_nw; nw["branchdc_ne"]["6"]["cost"] = 1471.72/no_nw;
                  nw["branchdc_ne"]["7"]["cost"] = 212.92/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 632.92/no_nw; nw["branchdc_ne"]["9"]["cost"] = 317.92/no_nw; nw["branchdc_ne"]["10"]["cost"] = 632.92/no_nw;
                  nw["branchdc_ne"]["11"]["cost"] = 212.92/no_nw; nw["branchdc_ne"]["12"]["cost"] = 736.72/no_nw;
                  nw["branchdc_ne"]["7"]["cost"] = 212.92*0.5/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 632.92*0.5/no_nw; nw["branchdc_ne"]["9"]["cost"] = 317.92*0.5/no_nw; nw["branchdc_ne"]["10"]["cost"] = 632.92*0.5/no_nw;
                  nw["branchdc_ne"]["11"]["cost"] = 212.92*0.5/no_nw; nw["branchdc_ne"]["12"]["cost"] = 736.72*0.5/no_nw;
       elseif PS == "Permanentloss"
           nw["convdc_ne"]["3"]["cost"] = 263.28/no_nw; nw["convdc_ne"]["4"]["cost"] = 263.28/no_nw; nw["convdc_ne"]["2"]["cost"] = 342.26/no_nw; nw["convdc_ne"]["1"]["cost"] = 342.26/no_nw
           # nw["convdc_ne"]["5"]["cost"] = 176.91/no_nw; nw["convdc_ne"]["6"]["cost"] = 176.91/no_nw; nw["convdc_ne"]["7"]["cost"] = 229.98/no_nw; nw["convdc_ne"]["8"]["cost"] = 229.98/no_nw

           nw["branchdc_ne"]["1"]["cost"] = 210/no_nw;
           nw["branchdc_ne"]["2"]["cost"] = 630/no_nw; nw["branchdc_ne"]["3"]["cost"] = 315/no_nw; nw["branchdc_ne"]["4"]["cost"] = 630/no_nw
           nw["branchdc_ne"]["5"]["cost"] = 210/no_nw; nw["branchdc_ne"]["6"]["cost"] = 735/no_nw;
           nw["branchdc_ne"]["7"]["cost"] = 210*0.5/no_nw;
           nw["branchdc_ne"]["8"]["cost"] = 630*0.5/no_nw; nw["branchdc_ne"]["9"]["cost"] = 315*0.5/no_nw; nw["branchdc_ne"]["10"]["cost"] = 630*0.5/no_nw;
           nw["branchdc_ne"]["11"]["cost"] = 210*0.5/no_nw; nw["branchdc_ne"]["12"]["cost"] = 735*0.5/no_nw;
        end
    end
    return data
end

function Protectionsystemcost_6bus(data, PS, no_nw)
    #no cost of permanent cost, ac side protection
    no_nw = no_nw
    for (n,nw) in data["nw"]
        display("nw:$n")
        if PS == "FS_HDCCB"
                  nw["convdc_ne"]["1"]["cost"] = 274.13/no_nw; nw["convdc_ne"]["3"]["cost"] = 274.13/no_nw; nw["convdc_ne"]["2"]["cost"] = 360.32/no_nw; nw["convdc_ne"]["4"]["cost"] = 360.32/no_nw
                  # nw["convdc_ne"]["5"]["cost"] = 143.56/no_nw; nw["convdc_ne"]["6"]["cost"] = 143.56/no_nw; nw["convdc_ne"]["7"]["cost"] = 189.27/no_nw; nw["convdc_ne"]["8"]["cost"] = 189.27/no_nw

                  # nw["branchdc_ne"]["1"]["cost"] = 448.91/no_nw;
                  nw["branchdc_ne"]["1"]["cost"] = 1288.91/no_nw; nw["branchdc_ne"]["2"]["cost"] = 658.91/no_nw; nw["branchdc_ne"]["3"]["cost"] = 1288.91/no_nw
                  nw["branchdc_ne"]["4"]["cost"] = 448.91/no_nw; nw["branchdc_ne"]["5"]["cost"] = 1491.7/no_nw;
                  # nw["branchdc_ne"]["7"]["cost"] = 232.36/no_nw;
                  nw["branchdc_ne"]["6"]["cost"] = 1288.91/no_nw; nw["branchdc_ne"]["7"]["cost"] = 1708.91/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 868.91/no_nw;
                  # nw["branchdc_ne"]["9"]["cost"] = 232.36/no_nw; nw["branchdc_ne"]["10"]["cost"] = 752.14/no_nw;

        elseif PS == "FS_MDCCB"
                  nw["convdc_ne"]["1"]["cost"] = 269.4/no_nw; nw["convdc_ne"]["3"]["cost"] = 269.4/no_nw; nw["convdc_ne"]["2"]["cost"] = 356.55/no_nw; nw["convdc_ne"]["4"]["cost"] = 356.55/no_nw
                  # nw["convdc_ne"]["5"]["cost"] = 140.32/no_nw; nw["convdc_ne"]["6"]["cost"] = 140.32/no_nw; nw["convdc_ne"]["7"]["cost"] = 188/no_nw; nw["convdc_ne"]["8"]["cost"] = 188/no_nw

                  # nw["branchdc_ne"]["1"]["cost"] = 440.40/no_nw;
                  nw["branchdc_ne"]["1"]["cost"] = 1280.41/no_nw; nw["branchdc_ne"]["2"]["cost"] = 650.40/no_nw; nw["branchdc_ne"]["3"]["cost"] = 1280.41/no_nw
                  nw["branchdc_ne"]["4"]["cost"] = 440.40/no_nw; nw["branchdc_ne"]["5"]["cost"] = 1482.24/no_nw;
                  # nw["branchdc_ne"]["7"]["cost"] = 227.84/no_nw;
                  nw["branchdc_ne"]["6"]["cost"] = 1280.41/no_nw; nw["branchdc_ne"]["7"]["cost"] = 1700.41/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 860.407/no_nw
                  # nw["branchdc_ne"]["9"]["cost"] = 227.84/no_nw; nw["branchdc_ne"]["10"]["cost"] = 745.66/no_nw;

        elseif PS == "NS_CB"
                  nw["convdc_ne"]["1"]["cost"] = 268.7/no_nw; nw["convdc_ne"]["3"]["cost"] = 268.7/no_nw; nw["convdc_ne"]["2"]["cost"] = 352.21/no_nw; nw["convdc_ne"]["4"]["cost"] = 352.21/no_nw
                  # nw["convdc_ne"]["5"]["cost"] = 140.41/no_nw; nw["convdc_ne"]["6"]["cost"] = 140.41/no_nw; nw["convdc_ne"]["7"]["cost"] = 185.43/no_nw; nw["convdc_ne"]["8"]["cost"] = 185.43/no_nw

                  # nw["branchdc_ne"]["1"]["cost"] = 440.40/no_nw;
                  nw["branchdc_ne"]["1"]["cost"] = 1280.41/no_nw; nw["branchdc_ne"]["2"]["cost"] = 650.40/no_nw; nw["branchdc_ne"]["3"]["cost"] = 1280.41/no_nw
                  nw["branchdc_ne"]["4"]["cost"] = 440.40/no_nw; nw["branchdc_ne"]["5"]["cost"] = 1482.24/no_nw;
                  # nw["branchdc_ne"]["7"]["cost"] = 227.84/no_nw;
                  nw["branchdc_ne"]["6"]["cost"] = 1280.41/no_nw; nw["branchdc_ne"]["7"]["cost"] = 1700.41/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 860.407/no_nw
                  # nw["branchdc_ne"]["9"]["cost"] = 227.84/no_nw; nw["branchdc_ne"]["10"]["cost"] = 745.66/no_nw;

        elseif PS == "NS_FB"
                  nw["convdc_ne"]["1"]["cost"] = 306.99/no_nw; nw["convdc_ne"]["3"]["cost"] = 306.99/no_nw; nw["convdc_ne"]["2"]["cost"] = 399.08/no_nw; nw["convdc_ne"]["4"]["cost"] = 399.08/no_nw
                  # nw["convdc_ne"]["5"]["cost"] = 176.91/no_nw; nw["convdc_ne"]["6"]["cost"] = 176.91/no_nw; nw["convdc_ne"]["7"]["cost"] = 229.98/no_nw; nw["convdc_ne"]["8"]["cost"] = 229.98/no_nw

                  # nw["branchdc_ne"]["1"]["cost"] = 422.92/no_nw;
                  nw["branchdc_ne"]["1"]["cost"] = 1262.93/no_nw; nw["branchdc_ne"]["2"]["cost"] = 632.92/no_nw; nw["branchdc_ne"]["3"]["cost"] = 1262.93/no_nw
                  nw["branchdc_ne"]["4"]["cost"] = 422.92/no_nw; nw["branchdc_ne"]["5"]["cost"] = 1471.72/no_nw;
                  # nw["branchdc_ne"]["7"]["cost"] = 212.92/no_nw;
                  nw["branchdc_ne"]["6"]["cost"] = 1262.93/no_nw; nw["branchdc_ne"]["7"]["cost"] = 1682.93/no_nw;
                  nw["branchdc_ne"]["8"]["cost"] = 842.92/no_nw;
                  # nw["branchdc_ne"]["9"]["cost"] = 212.92/no_nw; nw["branchdc_ne"]["10"]["cost"] = 736.72/no_nw;
        end
    end

    return data
end
# function Protectionsystemcost(data, PS, no_nw)
#     for (n,nw) in data["nw"]
#         display("nw:$n")
#         for (c,conv) in nw["convdc_ne"]
#             if PS == "NS_CB"
#                 if conv["Pacmax"] == 24
#                 conv["cost"] = conv["cost"] + 24/no_nw #line breaker are ignored
#                 elseif conv["Pacmax"] == 12
#                 conv["cost"] = conv["cost"] + 24*0.5/no_nw #line breaker are ignored
#                 end
#             elseif PS == "NS_FB"
#                 if conv["Pacmax"] == 24
#                     conv["cost"] = conv["cost"] + (193-150)/no_nw
#                 elseif conv["Pacmax"] == 12
#                     conv["cost"] = conv["cost"] + (193-150)*0.5/no_nw
#                 end
#             end
#         end
#         for (b,branch) in nw["branchdc_ne"]
#             if string(PS) == "FS_HDCCB"
#                 if branch["rateA"] == 24
#                     branch["cost"] = branch["cost"] + 47/no_nw
#                     display("br_cost:$(branch["cost"])")
#                 elseif branch["rateA"] == 12
#                     branch["cost"] = branch["cost"] + 47*0.5/no_nw
#                 end
#             elseif PS == "FS_MDCCB"
#                 if branch["rateA"] == 24
#                     branch["cost"] = branch["cost"] + 39/no_nw
#                 elseif branch["rateA"] == 12
#                     branch["cost"] = branch["cost"] + 39*0.5/no_nw
#                 end
#             elseif PS == "NS_FB"
#                 if branch["rateA"] == 24
#                     branch["cost"] = branch["cost"] + 6/no_nw
#                 elseif branch["rateA"] == 12
#                     branch["cost"] = branch["cost"] + 6*0.5/no_nw
#                 end
#             end
#         end
#     end
#     return data
# end




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
    display(curtailed_gen)
    curt = Any[]
     kkk=1
     for tt = 1:length(base_list)
             kkk= base_list[tt]
             available = sum(data_cont["nw"]["$kkk"]["gen"]["$i"]["pmax"] for i in curtailed_gen)
             generated = sum(resultDC1["solution"]["nw"]["$kkk"]["gen"]["$i"]["pg"] for i in curtailed_gen)
             # display(generated)
             # display("nw$tt: available:$available")
             # display("nw$tt: generated:$generated")
            curtailment = (available - generated)/available
            push!(curt, curtailment)
    end

    formax =[]
     for (n, nw) in resultDC1["solution"]["nw"]
            push!(formax, nw["reserves"]["2"]["Pff"])
    end
    formax1 =[]
     for (n, nw) in resultDC1["solution"]["nw"]
            push!(formax1, nw["reserves"]["2"]["Pgg"])
    end
    display(formax)
    display("curt: $(curt)")
    display("FFRmax: $(maximum(formax))")
     return curt, maximum(formax), maximum(formax1), mean(formax), mean(formax1)
end
