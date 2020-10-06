function constraint_frequency_stab_MP(pm::_PM.AbstractPowerModel) #gurobi
    if pm.setting["Permanentloss"] == true
        constraint_frequency_stab_OPF_MP_PL(pm)
    elseif pm.setting["FSprotection"] == true || pm.setting["NSprotection"] == true
        constraint_frequency_stab_OPF_MP_FSNS(pm)
    end
end

function constraint_frequency_stab_OPF_MP_PL(pm::_PM.AbstractPowerModel)
    base_nws = pm.setting["base_list"]
    cont_nws = pm.setting["Cont_list"]

    for (base, nw, br) in cont_nws
        load = _PM.ref(pm, nw, :load, 1)
        syncarea  = _PM.ids(pm, nw, :arcs_reserves_syn)
        Phvdcoaux = _PM.var(pm, nw)[:Phvdcoaux]
        Phvdccaux = _PM.var(pm, nw)[:Phvdccaux]
        Pconv1 = _PM.var(pm, base, :pconv_tf_fr)
        Pconv2 = _PM.var(pm, nw, :pconv_tf_fr)
        Zb1 = _PM.var(pm, nw)[:Zb1]

        # for i in syncarea
        i = 2
        JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"])
        JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"])
        JuMP.@constraint(pm.model,  Phvdccaux[i]  == 0)

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
        e = 1e-03
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
         k13 = _PM.var(pm, nw, :k13, i)

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


function constraint_frequency_stab_OPF_MP_FSNS(pm::_PM.AbstractPowerModel)
    base_nws = pm.setting["base_list"]
    cont_nws = pm.setting["Cont_list"]
    for (base, nw, br) in cont_nws
        load = _PM.ref(pm, nw, :load, 1)
        syncarea  = _PM.ids(pm, nw, :arcs_reserves_syn)
        Phvdcoaux = _PM.var(pm, nw)[:Phvdcoaux]
        Phvdccaux = _PM.var(pm, nw)[:Phvdccaux]
        Pconv1 = _PM.var(pm, base, :pconv_tf_fr)
        Pconv2 = _PM.var(pm, nw, :pconv_tf_fr)
        Zb1 = _PM.var(pm, nw)[:Zb1]

        # for i in syncarea
        i = 2
        if pm.setting["FSprotection"] == true
            display("FSprotection")
            JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= - (Pconv1[3]) /  load["pd"])
            JuMP.@constraint(pm.model,  Phvdcoaux[i]  <= - (Pconv1[3]) / load["pd"] + (72/ load["pd"])*(Zb1) )  #M = 72MW/load
            JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= - (Pconv1[4]) /  load["pd"])
            JuMP.@constraint(pm.model,  Phvdcoaux[i]  <= - (Pconv1[4]) / load["pd"] + (72/ load["pd"])*(1-Zb1) )

            JuMP.@constraint(pm.model,  Phvdccaux[i]  >= - (Pconv2[3]) /  load["pd"])
            JuMP.@constraint(pm.model,  Phvdccaux[i]  <= - (Pconv2[3]) / load["pd"] + (72/ load["pd"])*(Zb1) )
            JuMP.@constraint(pm.model,  Phvdccaux[i]  >= - (Pconv2[4]) /  load["pd"])
            JuMP.@constraint(pm.model,  Phvdccaux[i]  <= - (Pconv2[4]) / load["pd"] + (72/ load["pd"])*(1-Zb1) )

            JuMP.@constraint(pm.model,  Pconv1[3] - Pconv2[3] == Pconv1[4] - Pconv2[4])
        elseif pm.setting["NSprotection"] == true
            display("NSprotection")
            JuMP.@constraint(pm.model,  Phvdcoaux[i]  == - sum(Pconv1[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) /load["pd"])
            JuMP.@constraint(pm.model,  Phvdccaux[i]  == - sum(Pconv2[a] for a in _PM.ref(pm, nw, :bus_arcs_conv, i)) / load["pd"])
        end

        Pg = _PM.var(pm, nw, :Pgg, i)/load["pd"]
        Pf = _PM.var(pm, nw, :Pff, i)/load["pd"]

        reserves = _PM.ref(pm, nw, :reserves)
        bi_bp = Dict([((reserves["syncarea"]),i ) for (i,reserves) in _PM.ref(pm, nw, :reserves)])
        Td = reserves[bi_bp[i]]["Td"]
        Tg= reserves[bi_bp[i]]["Tg"]
        Tf = reserves[bi_bp[i]]["Tf"]
        H = reserves[bi_bp[i]]["H"]

        z1 = _PM.var(pm, nw, :z1, i)
        z2 = _PM.var(pm, nw, :z2, i)
        z3 = _PM.var(pm, nw, :z3, i)
        z4 = _PM.var(pm, nw, :z4, i)
        z5 = _PM.var(pm, nw, :z5, i)
        z11 = _PM.var(pm, nw, :z11, i)
        z21 = _PM.var(pm, nw, :z21, i)
        z31 = _PM.var(pm, nw, :z31, i)
        z41 = _PM.var(pm, nw, :z41, i)
        z12 = _PM.var(pm, nw, :z12, i)
        z22 = _PM.var(pm, nw, :z22, i)
        z32 = _PM.var(pm, nw, :z32, i)
        z42 = _PM.var(pm, nw, :z42, i)

        ############## frequency minimum in interval 1 ##########################################
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  +e <=   Pf + (Pg/Tg)*Tf + M*(1-z11))
         JuMP.@constraint(pm.model,  Phvdcoaux[i]  >= Pf + (Pg/Tg)*Tf - M*(z11))
         JuMP.@constraint(pm.model, 0 <=   Phvdcoaux[i]  + M*(1-z12))
         JuMP.@constraint(pm.model,  0  >= e +  Phvdcoaux[i]  - M*(z12))
         JuMP.@constraint(pm.model,  0 <= z11 + z12 - 2*z1)
         JuMP.@constraint(pm.model,  z11 + z12 - 2*z1 <= 1)

         k11 = _PM.var(pm, nw, :k11, i)
         k12 = _PM.var(pm, nw, :k12, i)
         k13 = _PM.var(pm, nw, :k13, i)

         JuMP.@constraint(pm.model,k11 ==  (H/50)*(Pg/Tg + Pf/Tf) )
         JuMP.@constraint(pm.model,k12 ==  (Phvdcoaux[i])/2)
         JuMP.@constraint(pm.model,k12^2 <=  k11)

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

         JuMP.@constraint(pm.model,k21 ==  (H/50 - Pf*Tf/4))
         JuMP.@constraint(pm.model,k22 ==  Pg/Tg)
         JuMP.@constraint(pm.model,k23 ==  (Phvdcoaux[i] - Pf)/2)

         JuMP.@constraint(pm.model,[k21/sqrt(2), k22/sqrt(2), k23, 0] in JuMP.RotatedSecondOrderCone() )

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

         JuMP.@constraint(pm.model, k31 ==  (H/50 - Pf*Tf/4 + Phvdccaux[i]*Tcl^2/(Td*4) ) )
         JuMP.@constraint(pm.model, k32 ==  (Pg/Tg + Phvdccaux[i]/Td) )
         JuMP.@constraint(pm.model, k33 ==  (Phvdcoaux[i] - Pf + Phvdccaux[i]*Tcl/Td)/2 )

         JuMP.@constraint(pm.model,[k31/sqrt(2), k32/sqrt(2), k33, 0] in JuMP.RotatedSecondOrderCone() )

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

        JuMP.@constraint(pm.model, k41 ==  (H/50 - Pf*Tf/4 - Phvdccaux[i]*(Td + 2*Tcl)/4) )
        JuMP.@constraint(pm.model, k42 ==  (Pg/Tg) )
        JuMP.@constraint(pm.model, k43 ==  (Phvdcoaux[i] - Pf - Phvdccaux[i])/2 )
        JuMP.@constraint(pm.model,[k41/sqrt(2), k42/sqrt(2), k43, 0] in JuMP.RotatedSecondOrderCone() )

         JuMP.@constraint(pm.model, z1 +z2 + z3+ z4 == 1)
     end
end
