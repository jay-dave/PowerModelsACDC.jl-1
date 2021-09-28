function constraint_frequency_stab_OPF_sensitivity(pm::_PM.AbstractPowerModel) #gurobi
    if pm.setting["Permanentloss"] == true
        constraint_frequency_stab_OPF_MP_PL_sensitivity(pm)
    elseif pm.setting["FSprotection"] == true || pm.setting["NSprotection"] == true
        constraint_frequency_stab_OPF_MP_FSNS_sensitivity(pm)
    end
end

function constraint_frequency_stab_OPF_MP_PL_sensitivity(pm::_PM.AbstractPowerModel)
    base_nws = pm.setting["base_list"]
    cont_nws = pm.setting["Cont_list"]
    ev_syncarea = pm.setting["syncarea"]

    for (base, nw, br) in cont_nws
        load = _PM.ref(pm, nw, :load, 1) # get index later on
        syncarea  = _PM.ids(pm, nw, :arcs_reserves_syn)
        Phvdcoaux = _PM.var(pm, nw)[:Phvdcoaux]
        Phvdccaux = _PM.var(pm, nw)[:Phvdccaux]
        Pconv1 = _PM.var(pm, base, :pconv_tf_fr)
        Pconv2 = _PM.var(pm, nw, :pconv_tf_fr)
        Zb1 = _PM.var(pm, nw)[:zb1]

        # for i in syncarea # when there is more than one synchornous areas
        i = ev_syncarea
        JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"])
        JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"])
        JuMP.@constraint(pm.model,  Phvdccaux[i]  == 0)

        JuMP.set_upper_bound(Phvdcoaux[i], 72/load["pd"])
        JuMP.set_upper_bound(Phvdccaux[i], 72/load["pd"])
        Pg = _PM.var(pm, nw, :Pgg, i)/load["pd"]
        Pf = _PM.var(pm, nw, :Pff, i)/load["pd"]
        reserves = _PM.ref(pm, nw, :reserves)
        bi_bp = Dict([((reserves["syncarea"]),i ) for (i,reserves) in _PM.ref(pm, nw, :reserves)])
        Td = reserves[bi_bp[i]]["Td"]
        Tg= reserves[bi_bp[i]]["Tg"]
        Tf = reserves[bi_bp[i]]["Tf"]
        H = reserves[bi_bp[i]]["H"]
        Tcl = reserves[bi_bp[i]]["Tcl"]
        M = 1 # largest possible Pl=0.15 for now

        z1 = _PM.var(pm, nw, :z1, i)
        z4 = _PM.var(pm, nw, :z4, i)
        z11 = _PM.var(pm, nw, :z11, i)
        z41 = _PM.var(pm, nw, :z41, i)
        z12 = _PM.var(pm, nw, :z12, i)
        z42 = _PM.var(pm, nw, :z42, i)
        e = 1e-06
        p2r = (50/(2*H))

        ############## frequency minimum in interval 1 ##########################################
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  +e <=   Pf + (Pg/Tg)*Tf + M*(1-z11))
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= Pf + (Pg/Tg)*Tf - M*(z11))
         JuMP.@constraint(pm.model, 0 <=   Phvdcoaux[i]  + M*(1-z12))
         JuMP.@constraint(pm.model,  0  >= e +  Phvdcoaux[i]  - M*(z12))
         JuMP.@constraint(pm.model,  0 <= z11 + z12 - 2*z1)
         JuMP.@constraint(pm.model,  z11 + z12 - 2*z1 <= 1)

          k11 = _PM.var(pm, nw, :k11, i)
          k12 = _PM.var(pm, nw, :k12, i)
          k11_dup = _PM.var(pm, nw, :k11_dup, i)
          k12_dup = _PM.var(pm, nw, :k12_dup, i)
          variable_on_off_switch(pm, k11, k11_dup, M, z1)
          variable_on_off_switch(pm, k12, k12_dup, M, z1)


          JuMP.@constraint(pm.model,k11 ==  (H/50)*(Pg/Tg + Pf/Tf) )
          JuMP.@constraint(pm.model,k12 ==  (Phvdcoaux[i])/2)
          JuMP.@constraint(pm.model,k12_dup^2 <=  k11_dup)

         ############## frequency minimum in interval 2 ##########################################
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  + e <=   Pf + Pg +  M*(1-z41))
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= Pf + Pg   - M*(z41))
         JuMP.@constraint(pm.model, Pf + (Pg/Tg)*(Tf)   <=   Phvdcoaux[i]  + M*(1-z42))
         JuMP.@constraint(pm.model,  Pf + (Pg/Tg)*(Tf)   >= e +  Phvdcoaux[i]  - M*(z42))
         JuMP.@constraint(pm.model,  0 <= z41 + z42 - 2*z4)
         JuMP.@constraint(pm.model,  z41 + z42 - 2*z4 <= 1)

         k41 = _PM.var(pm, nw, :k41, i)
         k42 = _PM.var(pm, nw, :k42, i)
         k43 = _PM.var(pm, nw, :k43, i)
         k41_dup = _PM.var(pm, nw, :k41_dup, i)
         k42_dup = _PM.var(pm, nw, :k42_dup, i)
         k43_dup = _PM.var(pm, nw, :k43_dup, i)
         variable_on_off_switch(pm, k41, k41_dup, M, z4)
         variable_on_off_switch(pm, k42, k42_dup, M, z4)
         variable_on_off_switch(pm, k43, k43_dup, M, z4)

         JuMP.@constraint(pm.model, k41 ==  (H/50 - Pf*Tf/4) )
         JuMP.@constraint(pm.model, k42 ==  (Pg/Tg) )
         JuMP.@constraint(pm.model, k43 ==  (Phvdcoaux[i] - Pf )/2 )
         JuMP.@constraint(pm.model,[k41_dup/sqrt(2), k42_dup/sqrt(2), k43_dup, 0] in JuMP.RotatedSecondOrderCone() )

         JuMP.@constraint(pm.model, z1 + z4 == 1)
     end
end


function constraint_frequency_stab_OPF_MP_FSNS_sensitivity(pm::_PM.AbstractPowerModel)

    base_nws = pm.setting["base_list"]
    cont_nws = pm.setting["Cont_list"]
    ev_syncarea = pm.setting["syncarea"]

    for (base, nw, br) in cont_nws
        load = _PM.ref(pm, nw, :load, 1)
        syncarea  = _PM.ids(pm, nw, :arcs_reserves_syn)
        Phvdcoaux = _PM.var(pm, nw)[:Phvdcoaux]
        Phvdccaux = _PM.var(pm, nw)[:Phvdccaux]
        Pconv1 = _PM.var(pm, base, :pconv_tf_fr)
        Pconv2 = _PM.var(pm, nw, :pconv_tf_fr)
        Zb1 = _PM.var(pm, nw)[:zb1]
        # for i in syncarea
        i = ev_syncarea
        conv_conn = _PM.ref(pm, nw, :bus_arcs_conv, i)

        if pm.setting["FSprotection"] == true
            # display("FSprotection")
            Mmax = 72/ load["pd"]
            display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_convs_dirct, i)) / load["pd"]) )
            display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - 0.5*sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_convs_dirct, i)) /load["pd"]) )
            # display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) /load["pd"] + sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) /load["pd"] ) )
         elseif pm.setting["NSprotection"] == true
            # display("NSprotection")
            # display(load["pd"])
            display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) /load["pd"]))
            display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - 0.5*sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"]))
        end

        JuMP.set_upper_bound(Phvdcoaux[i], 72/load["pd"])
        JuMP.set_upper_bound(Phvdccaux[i], 72/load["pd"])
        Pg = _PM.var(pm, nw, :Pgg, i)/load["pd"]
        Pf = _PM.var(pm, nw, :Pff, i)/load["pd"]

        reserves = _PM.ref(pm, nw, :reserves)
        bi_bp = Dict([((reserves["syncarea"]),i ) for (i,reserves) in _PM.ref(pm, nw, :reserves)])
        Td = reserves[bi_bp[i]]["Td"]
        Tg= reserves[bi_bp[i]]["Tg"]
        Tf = reserves[bi_bp[i]]["Tf"]
        Tcl = reserves[bi_bp[i]]["Tcl"]
        H = reserves[bi_bp[i]]["H"]

        z1 = _PM.var(pm, nw, :z1, i)
        z2 = _PM.var(pm, nw, :z2, i)
        z3 = _PM.var(pm, nw, :z3, i)
        z4 = _PM.var(pm, nw, :z4, i)
        z11 = _PM.var(pm, nw, :z11, i)
        z21 = _PM.var(pm, nw, :z21, i)
        z31 = _PM.var(pm, nw, :z31, i)
        z41 = _PM.var(pm, nw, :z41, i)
        z12 = _PM.var(pm, nw, :z12, i)
        z22 = _PM.var(pm, nw, :z22, i)
        z32 = _PM.var(pm, nw, :z32, i)
        z42 = _PM.var(pm, nw, :z42, i)
        e = 1e-06
        p2r = (50/(2*H))
        M = 1
        # M = ub(Pf + Pg +  Phvdccaux[i])
       ############## frequency minimum in interval 1 ##########################################
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  +e <=   Pf + (Pg/Tg)*Tf + M*(1-z11))
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= Pf + (Pg/Tg)*Tf - M*(z11))
         JuMP.@constraint(pm.model, 0 <=   Phvdcoaux[i]  + M*(1-z12))
         JuMP.@constraint(pm.model,  0  >= e +  Phvdcoaux[i]  - M*(z12))
         JuMP.@constraint(pm.model,  0 <= z11 + z12 - 2*z1)
         JuMP.@constraint(pm.model,  z11 + z12 - 2*z1 <= 1)

         k11 = _PM.var(pm, nw, :k11, i)
         k12 = _PM.var(pm, nw, :k12, i)
         k11_dup = _PM.var(pm, nw, :k11_dup, i)
         k12_dup = _PM.var(pm, nw, :k12_dup, i)
         variable_on_off_switch(pm, k11, k11_dup, M, z1)
         variable_on_off_switch(pm, k12, k12_dup, M, z1)


         JuMP.@constraint(pm.model,k11 ==  (H/50)*(Pg/Tg + Pf/Tf) )
         JuMP.@constraint(pm.model,k12 ==  (Phvdcoaux[i])/2)
         JuMP.@constraint(pm.model,k12_dup^2 <=  k11_dup)

     ############## frequency minimum in interval 2 ##########################################
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  +e  <=  Pf + (Pg/Tg)*Tcl + M*(1-z21))
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= Pf + (Pg/Tg)*Tcl - M*(z21))
         JuMP.@constraint(pm.model, Pf + (Pg/Tg)*Tf <=   Phvdcoaux[i]  + M*(1-z22))
         JuMP.@constraint(pm.model,  Pf + (Pg/Tg)*Tf  >= e +  Phvdcoaux[i]  - M*(z22))
         JuMP.@constraint(pm.model,  0 <= z21 + z22 - 2*z2)
         JuMP.@constraint(pm.model,  z21 + z22 - 2*z2 <= 1)

         k21 = _PM.var(pm, nw, :k21, i)
         k22 = _PM.var(pm, nw, :k22, i)
         k23 = _PM.var(pm, nw, :k23, i)

         k21_dup = _PM.var(pm, nw, :k21_dup, i)
         k22_dup = _PM.var(pm, nw, :k22_dup, i)
         k23_dup = _PM.var(pm, nw, :k23_dup, i)
         variable_on_off_switch(pm, k21, k21_dup, M, z2)
         variable_on_off_switch(pm, k22, k22_dup, M, z2)
         variable_on_off_switch(pm, k23, k23_dup, M, z2)

         JuMP.@constraint(pm.model,k21 ==  (H/50 - Pf*Tf/4))
         JuMP.@constraint(pm.model,k22 ==  Pg/Tg)
         JuMP.@constraint(pm.model,k23 ==  (Phvdcoaux[i] - Pf)/2)

         JuMP.@constraint(pm.model,[k21_dup/sqrt(2), k22_dup/sqrt(2), k23_dup, 0] in JuMP.RotatedSecondOrderCone() )

         ############## frequency minimum in interval 3 ##########################################
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  +e  <=   Pf + (Pg/Tg)*(Tcl+Td) +  Phvdccaux[i]  + M*(1-z31))
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= Pf + (Pg/Tg)*(Tcl+Td) +  Phvdccaux[i]  - M*(z31))
         JuMP.@constraint(pm.model, Pf + (Pg/Tg)*Tcl <=   Phvdcoaux[i]  + M*(1-z32))
         JuMP.@constraint(pm.model,  Pf + (Pg/Tg)*Tcl  >= e+  Phvdcoaux[i]  - M*(z32))
         JuMP.@constraint(pm.model,  0 <= z31 + z32 - 2*z3)
         JuMP.@constraint(pm.model,  z31 + z32 - 2*z3 <= 1)

         k31 = _PM.var(pm, nw, :k31, i)
         k32 = _PM.var(pm, nw, :k32, i)
         k33 = _PM.var(pm, nw, :k33, i)
         k31_dup = _PM.var(pm, nw, :k31_dup, i)
         k32_dup = _PM.var(pm, nw, :k32_dup, i)
         k33_dup = _PM.var(pm, nw, :k33_dup, i)
         variable_on_off_switch(pm, k31, k31_dup, M, z3)
         variable_on_off_switch(pm, k32, k32_dup, M, z3)
         variable_on_off_switch(pm, k33, k33_dup, M, z3)

         JuMP.@constraint(pm.model, k31 ==  (H/50 - Pf*Tf/4 + Phvdccaux[i]*Tcl^2/(Td*4) ) )
         JuMP.@constraint(pm.model, k32 ==  (Pg/Tg + Phvdccaux[i]/Td) )
         JuMP.@constraint(pm.model, k33 ==  (Phvdcoaux[i] - Pf + Phvdccaux[i]*Tcl/Td)/2 )

         display(JuMP.@constraint(pm.model,[k31_dup/sqrt(2), k32_dup/sqrt(2), k33_dup, 0] in JuMP.RotatedSecondOrderCone() ))

        ############## frequency minimum in interval 4 ##########################################
        JuMP.@constraint(pm.model,  Phvdcoaux[i]  + e <=   Pf + Pg +  Phvdccaux[i]  + M*(1-z41))
        JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= Pf + Pg +  Phvdccaux[i]  - M*(z41))
        JuMP.@constraint(pm.model, Pf + (Pg/Tg)*(Tcl+Td) +  Phvdccaux[i]  <=   Phvdcoaux[i]  + M*(1-z42))
        JuMP.@constraint(pm.model,  Pf + (Pg/Tg)*(Tcl+Td) +  Phvdccaux[i]   >= e +  Phvdcoaux[i]  - M*(z42))
        JuMP.@constraint(pm.model,  0 <= z41 + z42 - 2*z4)
        JuMP.@constraint(pm.model,  z41 + z42 - 2*z4 <= 1)

        k41 = _PM.var(pm, nw, :k41, i)
        k42 = _PM.var(pm, nw, :k42, i)
        k43 = _PM.var(pm, nw, :k43, i)
        k41_dup = _PM.var(pm, nw, :k41_dup, i)
        k42_dup = _PM.var(pm, nw, :k42_dup, i)
        k43_dup = _PM.var(pm, nw, :k43_dup, i)
        variable_on_off_switch(pm, k41, k41_dup, M, z4)
        variable_on_off_switch(pm, k42, k42_dup, M, z4)
        variable_on_off_switch(pm, k43, k43_dup, M, z4)

        JuMP.@constraint(pm.model, k41 ==  (H/50 - Pf*Tf/4 - Phvdccaux[i]*(Td + 2*Tcl)/4) )
        JuMP.@constraint(pm.model, k42 ==  (Pg/Tg) )
        JuMP.@constraint(pm.model, k43 ==  (Phvdcoaux[i] - Pf - Phvdccaux[i])/2 )
        JuMP.@constraint(pm.model,[k41_dup/sqrt(2), k42_dup/sqrt(2), k43_dup, 0] in JuMP.RotatedSecondOrderCone() )

        JuMP.@constraint(pm.model,  z1+z2+z3+z4 == 1)

     end
end

function variable_frequency_stab_OPF(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    t1 = _PM.var(pm, nw)[:t1] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_t1",  lower_bound = 0,  upper_bound = 10, start = 0)
    t2 = _PM.var(pm, nw)[:t2] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_t2",  lower_bound = 0,  upper_bound = 10, start = 0)
    t3 = _PM.var(pm, nw)[:t3] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_t3",  lower_bound = 0,  upper_bound = 10, start = 0)
    t4 = _PM.var(pm, nw)[:t4] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_t4",  lower_bound = 0,  upper_bound = 10, start = 0)

    # f1 = _PM.var(pm)[:f1] = JuMP.@variable(pm.model, base_name="df1",  lower_bound = -10,  upper_bound = 10, start = 0)
    # f2 = _PM.var(pm)[:f2] = JuMP.@variable(pm.model, base_name="df2",  lower_bound = -10,  upper_bound = 10, start = 0)
    # f3 = _PM.var(pm)[:f3] = JuMP.@variable(pm.model, base_name="df3",  lower_bound = -10,  upper_bound = 10, start = 0)
    # f4 = _PM.var(pm)[:f4] = JuMP.@variable(pm.model, base_name="df4",  lower_bound = -10,  upper_bound = 10, start = 0)

    f1 = _PM.var(pm, nw)[:f1] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_df1",  lower_bound = -10,  upper_bound = 10, start = 0)
    f2 = _PM.var(pm, nw)[:f2] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_df2",  lower_bound = -10,  upper_bound = 10, start = 0)
    f3 = _PM.var(pm, nw)[:f3] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_df3",  lower_bound = -10,  upper_bound = 10, start = 0)
    f4 = _PM.var(pm, nw)[:f4] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_df4",  lower_bound = -10,  upper_bound = 10, start = 0)

    report && _IM.sol_component_value(pm, nw, :reserves, :df, _PM.ids(pm, nw, :arcs_reserves_syn), df)
    report && _IM.sol_component_value(pm, nw, :reserves, :dt, _PM.ids(pm, nw, :arcs_reserves_syn), dt)

    report && _IM.sol_component_value(pm, nw, :reserves, :f1, _PM.ids(pm, nw, :arcs_reserves_syn), f1)
    report && _IM.sol_component_value(pm, nw, :reserves, :f2, _PM.ids(pm, nw, :arcs_reserves_syn), f2)
    report && _IM.sol_component_value(pm, nw, :reserves, :f3, _PM.ids(pm, nw, :arcs_reserves_syn), f3)
    report && _IM.sol_component_value(pm, nw, :reserves, :f4, _PM.ids(pm, nw, :arcs_reserves_syn), f4)
    report && _IM.sol_component_value(pm, nw, :reserves, :t1, _PM.ids(pm, nw, :arcs_reserves_syn), t1)
    report && _IM.sol_component_value(pm, nw, :reserves, :t2, _PM.ids(pm, nw, :arcs_reserves_syn), t2)
    report && _IM.sol_component_value(pm, nw, :reserves, :t3, _PM.ids(pm, nw, :arcs_reserves_syn), t3)
    report && _IM.sol_component_value(pm, nw, :reserves, :t4, _PM.ids(pm, nw, :arcs_reserves_syn), t4)
end


function variable_on_off_switch(pm, k, k_dup, M , z)
    M = 100 # M=1 was binding for nonactivated K
    JuMP.@constraint(pm.model,  k_dup  >=  k - M*(1-z) )
    JuMP.@constraint(pm.model,  k_dup  <=  k + M*(1-z) )
    JuMP.@constraint(pm.model,  k_dup  >=  -M*z )
    JuMP.@constraint(pm.model,  k_dup  <=  M*z )
end
