function constraint_frequency_stab_OPF(pm::_PM.AbstractPowerModel) #gurobi
    if pm.setting["Permanentloss"] == true
        constraint_frequency_stab_OPF_MP_PL(pm)
    elseif pm.setting["FSprotection"] == true || pm.setting["NSprotection"] == true
        constraint_frequency_stab_OPF_MP_FSNS(pm)
    end
end

function constraint_frequency_stab_OPF_MP_PL(pm::_PM.AbstractPowerModel)
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
        JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4] )
        JuMP.@constraint(pm.model,  Pconv1[3]== Pconv1[4])

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

function constraint_frequency_stab_OPF_MP_FSNS(pm::_PM.AbstractPowerModel)
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
            # for k in conv_conn
            #     display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= - (Pconv1[k]) /  load["pd"]) )
            #     display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  <= - (Pconv1[k]) / load["pd"] + Mmax*(1-Zb1[k]) ) )
            #     display(JuMP.@constraint(pm.model,  Phvdccaux[i]  >= - Pconv2[k] /  load["pd"] -  Mmax*(1-Zb1[k]) ) )
            #     display(JuMP.@constraint(pm.model,  Phvdccaux[i]  <= - Pconv2[k] / load["pd"] +   Mmax*(1-Zb1[k]) ) )
            # end
            # JuMP.@constraint(pm.model,  sum(Zb1[k] for k in conv_conn)==1 )

            display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_convs_dirct, i)) / load["pd"]) )
            display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_convs_dirct, i)) /load["pd"]) )
            # display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) /load["pd"] + sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) /load["pd"] ) )
            JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4] )
            JuMP.@constraint(pm.model,  Pconv1[3]== Pconv1[4])

         elseif pm.setting["NSprotection"] == true
            # display("NSprotection")
            # display(load["pd"])
            display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) /load["pd"]))
            display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"]))
            JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4])
            JuMP.@constraint(pm.model,  Pconv1[3]== Pconv1[4])

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

         JuMP.@constraint(pm.model, z1 +z2 + z3+ z4 == 1)
     end
end

function constraint_frequency_stab_TNEP(pm::_PM.AbstractPowerModel)
    if pm.setting["Permanentloss"] == true
        constraint_frequency_stab_TNEP_MP_PL(pm)
    elseif pm.setting["FSprotection"] == true || pm.setting["NSprotection"] == true
        constraint_frequency_stab_TNEP_MP_FSNS(pm)
    end
end

function constraint_frequency_stab_TNEP_MP_PL(pm::_PM.AbstractPowerModel)
        base_nws = pm.setting["base_list"]
        cont_nws = pm.setting["Cont_list"]
		ev_syncarea = pm.setting["syncarea"]

        for (base, n, br) in cont_nws
        nw = n
        conv = _PM.ref(pm, :convdc)
        load = _PM.ref(pm, nw, :load, 1)
		syncarea  = _PM.ids(pm, nw, :arcs_reserves_syn_ne)
        Phvdcoaux = _PM.var(pm, nw)[:Phvdcoaux]
        Phvdccaux = _PM.var(pm, nw)[:Phvdccaux]
        Phvdcoaux_dup = _PM.var(pm, nw)[:Phvdcoaux_dup]
        Phvdccaux_dup = _PM.var(pm, nw)[:Phvdccaux_dup]
        Pconv1 = _PM.var(pm, base, :pconv_tf_fr_ne)
        Pconv2 = _PM.var(pm, nw, :pconv_tf_fr_ne)
        Zb1 = _PM.var(pm, nw)[:zb1]

        i = ev_syncarea
        # for i in syncarea
        # JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv_ne, i)) / load["pd"])
        # JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv_ne, i)) / load["pd"])
        # JuMP.@constraint(pm.model,  Phvdccaux[i]  == 0)

        display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_incident_ne, br)) / load["pd"]) ) #sync. area is not implemented
        display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_incident_ne, br)) /  load["pd"]) ) #sync. area is not implemented
        for a in _PM.ref(pm, nw, :bus_arcs_incident_ne, br)
            display(JuMP.@constraint(pm.model,  Pconv2[a] == 0 ) ) #chagne in OPF but shouldnt make too much difference. The problem here is that it causes other converters not to build
        end
        # JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4])
        # JuMP.@constraint(pm.model,  Pconv1[3]== Pconv1[4])

         #
        JuMP.set_upper_bound(Phvdcoaux[i], 72/load["pd"])
        JuMP.set_upper_bound(Phvdccaux[i], 72/load["pd"])
        zbr = _PM.var(pm, nw, :branchdc_ne, br)

        JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >=  Phvdcoaux[i] - JuMP.upper_bound(Phvdcoaux[i])*(1-zbr) )
        JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  <=  Phvdcoaux[i] - JuMP.lower_bound(Phvdcoaux[i])*(1-zbr) )
        JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >=  JuMP.lower_bound(Phvdcoaux[i])*(zbr) )
        JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  <=  JuMP.upper_bound(Phvdcoaux[i])*(zbr) )

        JuMP.@constraint(pm.model,  Phvdccaux_dup[i]  >=  Phvdccaux[i] - JuMP.upper_bound(Phvdcoaux[i])*(1-zbr) )
        JuMP.@constraint(pm.model,  Phvdccaux_dup[i]  <=  Phvdccaux[i] - JuMP.lower_bound(Phvdcoaux[i])*(1-zbr) )
        JuMP.@constraint(pm.model,  Phvdccaux_dup[i]  >=  JuMP.lower_bound(Phvdccaux[i])*(zbr) )
        JuMP.@constraint(pm.model,  Phvdccaux_dup[i]  <=  JuMP.upper_bound(Phvdccaux[i])*(zbr) )

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
        M = 1

        ####################################################################################
         JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  +e <=   Pf + (Pg/Tg)*Tf + M*(1-z11))
         JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >= Pf + (Pg/Tg)*Tf - M*(z11))
         JuMP.@constraint(pm.model, 0 <=   Phvdcoaux_dup[i]  + M*(1-z12))
         JuMP.@constraint(pm.model,  0  >= e +  Phvdcoaux_dup[i]  - M*(z12))
         JuMP.@constraint(pm.model,  0 <= z11 + z12 - 2*z1)
         JuMP.@constraint(pm.model,  z11 + z12 - 2*z1 <= 1)

         k11 = _PM.var(pm, nw, :k11, i)
         k12 = _PM.var(pm, nw, :k12, i)
         k11_dup = _PM.var(pm, nw, :k11_dup, i)
         k12_dup = _PM.var(pm, nw, :k12_dup, i)
         variable_on_off_switch(pm, k11, k11_dup, M, z1)
         variable_on_off_switch(pm, k12, k12_dup, M, z1)

         JuMP.@constraint(pm.model,k11 ==  (H/50)*(Pg/Tg + Pf/Tf) )
         JuMP.@constraint(pm.model,k12 ==  (Phvdcoaux_dup[i])/2)
         JuMP.@constraint(pm.model,k12_dup^2 <=  k11_dup)

       ####################################################################################
       JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  + e <=   Pf + Pg +  M*(1-z41))
       JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >= Pf + Pg   - M*(z41))
       JuMP.@constraint(pm.model, Pf + (Pg/Tg)*(Tf)   <=   Phvdcoaux_dup[i]  + M*(1-z42))
       JuMP.@constraint(pm.model,  Pf + (Pg/Tg)*(Tf)   >= e +  Phvdcoaux_dup[i]  - M*(z42))
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
       JuMP.@constraint(pm.model, k43 ==  (Phvdcoaux_dup[i] - Pf )/2 )
       JuMP.@constraint(pm.model,[k41_dup/sqrt(2), k42_dup/sqrt(2), k43_dup, 0] in JuMP.RotatedSecondOrderCone() )

       JuMP.@constraint(pm.model, z1 + z4 == 1)
        end
end

function constraint_frequency_stab_TNEP_MP_FSNS(pm::_PM.AbstractPowerModel)
    base_nws = pm.setting["base_list"]
    cont_nws = pm.setting["Cont_list"]
    ev_syncarea = pm.setting["syncarea"]
    for (base, nw, br) in cont_nws
        load = _PM.ref(pm, nw, :load, 1) # get index later on
        syncarea  = _PM.ids(pm, nw, :arcs_reserves_syn_ne)
        Phvdcoaux = _PM.var(pm, nw)[:Phvdcoaux]
        Phvdccaux = _PM.var(pm, nw)[:Phvdccaux]
        Phvdcoaux_dup = _PM.var(pm, nw)[:Phvdcoaux_dup]
        Phvdccaux_dup = _PM.var(pm, nw)[:Phvdccaux_dup]
        Pconv1 = _PM.var(pm, base, :pconv_tf_fr_ne)
        Pconv2 = _PM.var(pm, nw, :pconv_tf_fr_ne)
        Zb1 = _PM.var(pm, nw)[:zb1]

        i = ev_syncarea
        conv_conn = _PM.ref(pm, nw, :bus_arcs_conv_ne, i)
        Mmax = 72/ load["pd"] # 72MW = 24MW*3 highest onshroe rating for all test cases
        if pm.setting["FSprotection"] == true
            display(_PM.ref(pm, nw, :bus_convs_dirct_ne) )
            display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_convs_dirct_ne, i)) / load["pd"]) )
            display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_convs_dirct_ne, i)) /load["pd"]) )
            # for k in conv_conn
            #     display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= - (Pconv1[k]) /  load["pd"]) )
            #     display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  <= - (Pconv1[k]) / load["pd"] + Mmax*(1-Zb1[k]) ) )
            #     display(JuMP.@constraint(pm.model,  Phvdccaux[i]  >= - Pconv2[k] /  load["pd"] -  Mmax*(1-Zb1[k]) ) )
            #     display(JuMP.@constraint(pm.model,  Phvdccaux[i]  <= - Pconv2[k] / load["pd"] +   Mmax*(1-Zb1[k]) ) )
            # end
            JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4])
            JuMP.@constraint(pm.model,  Pconv1[3]== Pconv1[4])
            # display(JuMP.@constraint(pm.model,  sum(Zb1[k] for k in conv_conn)==1 ) )
            # display(JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4] ) ) # what if a conv is not built, find a way around to know what is built
        elseif pm.setting["NSprotection"] == true
            #old
            # display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv_ne, i)) / load["pd"]) )
            # display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv_ne, i)) /  load["pd"]) )
            #new
            display(JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_incident_ne, br)) / load["pd"]) ) #sync. area is not implemented
            display(JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_incident_ne, br)) /  load["pd"]) ) #sync. area is not implemented
            # display(JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4] ) ) # what if a conv not built, find a way around to know what is built
            JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4])
            JuMP.@constraint(pm.model,  Pconv1[3]== Pconv1[4])
        end

        JuMP.set_upper_bound(Phvdcoaux[i], 72/load["pd"])
        JuMP.set_upper_bound(Phvdccaux[i], 72/load["pd"])
        zbr = _PM.var(pm, nw, :branchdc_ne, br)

        JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >=  Phvdcoaux[i] - JuMP.upper_bound(Phvdcoaux[i])*(1-zbr) )
        JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  <=  Phvdcoaux[i] - JuMP.lower_bound(Phvdcoaux[i])*(1-zbr) )
        JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >=  JuMP.lower_bound(Phvdcoaux[i])*(zbr) )
        JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  <=  JuMP.upper_bound(Phvdcoaux[i])*(zbr) )
        #
        JuMP.@constraint(pm.model,  Phvdccaux_dup[i]  >=  Phvdccaux[i] - JuMP.upper_bound(Phvdcoaux[i])*(1-zbr) )
        JuMP.@constraint(pm.model,  Phvdccaux_dup[i]  <=  Phvdccaux[i] - JuMP.lower_bound(Phvdcoaux[i])*(1-zbr) )
        JuMP.@constraint(pm.model,  Phvdccaux_dup[i]  >=  JuMP.lower_bound(Phvdccaux[i])*(zbr) )
        JuMP.@constraint(pm.model,  Phvdccaux_dup[i]  <=  JuMP.upper_bound(Phvdccaux[i])*(zbr) )

        #check if pf and pg need to be disabled when a branch is not built since the FFR_list still accounts the pf,pg for nonbuilt branches..
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

        ############## frequency minimum in interval 1 ##########################################
         JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  +e <=   Pf + (Pg/Tg)*Tf + M*(1-z11))
         JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >= Pf + (Pg/Tg)*Tf - M*(z11))
         JuMP.@constraint(pm.model, 0 <=   Phvdcoaux_dup[i]  + M*(1-z12))
         JuMP.@constraint(pm.model,  0  >= e +  Phvdcoaux_dup[i]  - M*(z12))
         JuMP.@constraint(pm.model,  0 <= z11 + z12 - 2*z1)
         JuMP.@constraint(pm.model,  z11 + z12 - 2*z1 <= 1)

         k11 = _PM.var(pm, nw, :k11, i)
         k12 = _PM.var(pm, nw, :k12, i)
         k11_dup = _PM.var(pm, nw, :k11_dup, i)
         k12_dup = _PM.var(pm, nw, :k12_dup, i)
         variable_on_off_switch(pm, k11, k11_dup, M, z1)
         variable_on_off_switch(pm, k12, k12_dup, M, z1)

         JuMP.@constraint(pm.model,k11 ==  (H/50)*(Pg/Tg + Pf/Tf) )
         JuMP.@constraint(pm.model,k12 ==  (Phvdcoaux_dup[i])/2)
         JuMP.@constraint(pm.model,k12_dup^2 <=  k11_dup)

         ############## frequency minimum in interval 2 ##########################################
           JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  +e  <=  Pf + (Pg/Tg)*Tcl + M*(1-z21))
           JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >= Pf + (Pg/Tg)*Tcl - M*(z21))
           JuMP.@constraint(pm.model, Pf + (Pg/Tg)*Tf <=   Phvdcoaux_dup[i]  + M*(1-z22))
           JuMP.@constraint(pm.model,  Pf + (Pg/Tg)*Tf  >= e +  Phvdcoaux_dup[i]  - M*(z22))
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
           JuMP.@constraint(pm.model,k23 ==  (Phvdcoaux_dup[i] - Pf)/2)

           JuMP.@constraint(pm.model,[k21_dup/sqrt(2), k22_dup/sqrt(2), k23_dup, 0] in JuMP.RotatedSecondOrderCone() )

           ############## frequency minimum in interval 3 ##########################################
         # JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  +e  <=   Pf + (Pg/Tg)*(Tcl+Td) +  Phvdccaux_dup[i]  + M*(1-z31))
         # JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >= Pf + (Pg/Tg)*(Tcl+Td) +  Phvdccaux_dup[i]  - M*(z31))
         # JuMP.@constraint(pm.model, Pf + (Pg/Tg)*Tcl <=   Phvdcoaux_dup[i]  + M*(1-z32))
         # JuMP.@constraint(pm.model,  Pf + (Pg/Tg)*Tcl  >= e+  Phvdcoaux_dup[i]  - M*(z32))
         # JuMP.@constraint(pm.model,  0 <= z31 + z32 - 2*z3)
         # JuMP.@constraint(pm.model,  z31 + z32 - 2*z3 <= 1)
         #
         # k31 = _PM.var(pm, nw, :k31, i)
         # k32 = _PM.var(pm, nw, :k32, i)
         # k33 = _PM.var(pm, nw, :k33, i)
         # k31_dup = _PM.var(pm, nw, :k31_dup, i)
         # k32_dup = _PM.var(pm, nw, :k32_dup, i)
         # k33_dup = _PM.var(pm, nw, :k33_dup, i)
         # variable_on_off_switch(pm, k31, k31_dup, M, z3)
         # variable_on_off_switch(pm, k32, k32_dup, M, z3)
         # variable_on_off_switch(pm, k33, k33_dup, M, z3)
         #
         # JuMP.@constraint(pm.model, k31 ==  (H/50 - Pf*Tf/4 + Phvdccaux_dup[i]*Tcl^2/(Td*4) ) )
         # JuMP.@constraint(pm.model, k32 ==  (Pg/Tg + Phvdccaux_dup[i]/Td) )
         # JuMP.@constraint(pm.model, k33 ==  (Phvdcoaux_dup[i] - Pf + Phvdccaux_dup[i]*Tcl/Td)/2 )
         #
         # JuMP.@constraint(pm.model,[k31_dup/sqrt(2), k32_dup/sqrt(2), k33_dup, 0] in JuMP.RotatedSecondOrderCone() )

         ############## frequency minimum in interval 4 ##########################################
           JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  + e <=   Pf + Pg +  Phvdccaux_dup[i]  + M*(1-z41))
           JuMP.@constraint(pm.model,  Phvdcoaux_dup[i]  >= Pf + Pg +  Phvdccaux_dup[i]  - M*(z41))
           JuMP.@constraint(pm.model, Pf + (Pg/Tg)*(Tcl+Td) +  Phvdccaux_dup[i]  <=   Phvdcoaux_dup[i]  + M*(1-z42))
           JuMP.@constraint(pm.model,  Pf + (Pg/Tg)*(Tcl+Td) +  Phvdccaux_dup[i]   >= e +  Phvdcoaux_dup[i]  - M*(z42))
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

           JuMP.@constraint(pm.model, k41 ==  (H/50 - Pf*Tf/4 - Phvdccaux_dup[i]*(Td + 2*Tcl)/4) )
           JuMP.@constraint(pm.model, k42 ==  (Pg/Tg) )
           JuMP.@constraint(pm.model, k43 ==  (Phvdcoaux_dup[i] - Pf - Phvdccaux_dup[i])/2 )
           JuMP.@constraint(pm.model,[k41_dup/sqrt(2), k42_dup/sqrt(2), k43_dup, 0] in JuMP.RotatedSecondOrderCone() )

        JuMP.@constraint(pm.model, z1 +z2 + z4 == 1)

    end
end

function constraint_frequency_stab_OPF_MP_PLdim(pm::_PM.AbstractPowerModel)
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
        display("connstraint: post_acdcscopf_nocl_PLdim")
        JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"])
        JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"])
        JuMP.@constraint(pm.model,  Phvdccaux[i]  == 0)
        # JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4] )
        # JuMP.@constraint(pm.model,  Pconv1[3]== Pconv1[4])

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

         JuMP.@constraint(pm.model,k11 ==  (H/50)*(Pg/Tg + Pf/Tf) )
         JuMP.@constraint(pm.model,k12 ==  (Phvdcoaux[i])/2)
         JuMP.@constraint(pm.model,k12^2 <=  k11)

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

         JuMP.@constraint(pm.model, k41 ==  (H/50 - Pf*Tf/4) )
         JuMP.@constraint(pm.model, k42 ==  (Pg/Tg) )
         JuMP.@constraint(pm.model, k43 ==  (Phvdcoaux[i] - Pf )/2 )
         JuMP.@constraint(pm.model,[k41/sqrt(2), k42/sqrt(2), k43, 0] in JuMP.RotatedSecondOrderCone() )

         JuMP.@constraint(pm.model, z1 + z4 == 1)
     end
end
