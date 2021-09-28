""
function objective_min_fuel_cost(pm::_PM.AbstractPowerModel)
    model = _PM.check_cost_models(pm)
    if model == 1
        return objective_min_pwl_fuel_cost(pm)
    elseif model == 2
        return objective_min_polynomial_fuel_cost(pm)
    else
        error("Only cost models of types 1 and 2 are supported at this time, given cost model type of $(model)")
    end

end

""
function objective_min_polynomial_fuel_cost(pm::_PM.AbstractPowerModel)
    order = _PM.calc_max_cost_index(pm.data)-1

    if order == 1
        return _objective_min_polynomial_fuel_cost_linear(pm)
    elseif order == 2
        return _objective_min_polynomial_fuel_cost_quadratic(pm)
    else
        error("cost model order of $(order) is not supported")
    end
end

function _objective_min_polynomial_fuel_cost_linear(pm::_PM.AbstractPowerModel)
    from_idx = Dict()
    for (n, nw_ref) in nws(pm)
        from_idx[n] = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
    end

    return JuMP.@objective(pm.model, Min,
        sum(
            sum(   gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))+
                   gen["cost"][2] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in nws(pm))
    )
end
""
function _objective_min_polynomial_fuel_cost_quadratic(pm::_PM.AbstractPowerModel)
    from_idx = Dict()
    for (n, nw_ref) in nws(pm)
        from_idx[n] = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
    end

    return JuMP.@objective(pm.model, Min,
        sum(
            sum(   gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))^2 +
                   gen["cost"][2]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))+
                   gen["cost"][3] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in nws(pm))
    )
end
""
function objective_min_polynomial_fuel_cost(pm::_PM.AbstractConicModel)
    _PM.check_polynomial_cost_models(pm)
    pg_sqr = Dict()
    for (n, nw_ref) in _PM.nws(pm)
        for cnd in _PM.conductor__PM.ids(pm, n)
            pg_sqr = _PM.var(pm, n, cnd)[:pg_sqr] = JuMP.@variable(pm.model,
                [i in _PM.ids(pm, n, :gen)], base_name="$(n)_$(cnd)_pg_sqr",
                lower_bound = _PM.ref(pm, n, :gen, i, "pmin", cnd)^2,
                upper_bound = _PM.ref(pm, n, :gen, i, "pmax", cnd)^2
            )
            for (i, gen) in nw_ref[:gen]
                JuMP.@constraint(pm.model, [pg_sqr[i], var(pm, n, cnd, :pg, i)/sqrt(2), var(pm, n, cnd, :pg, i)/sqrt(2)] in JuMP.SecondOrderCone())
            end

        end
    end
    return JuMP.@objective(pm.model, Min,
        sum(
            sum( gen["cost"][1]*sum(_PM.var(pm, n, cnd, :pg_sqr, i) for cnd in _PM.conductor__PM.ids(pm, n)) +
                 gen["cost"][2]*sum(_PM.var(pm, n, cnd, :pg, i) for cnd in _PM.conductor__PM.ids(pm, n)) +
                 gen["cost"][3] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in _PM.nws(pm))
    )
end
""
function objective_min_pwl_fuel_cost(pm::_PM.AbstractPowerModel)

    for (n, nw_ref) in _PM.nws(pm)
        pg_cost = _PM.var(pm, n)[:pg_cost] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, n, :gen)], base_name="$(n)_pg_cost"
        )

        # pwl cost
        gen_lines = _PM.get_lines(nw_ref[:gen])
        for (i, gen) in nw_ref[:gen]
            for line in gen_lines[i]
                JuMP.@constraint(pm.model, pg_cost[i] >= line["slope"]*sum(_PM.var(pm, n, cnd, :pg, i) for cnd in _PM.conductor__PM.ids(pm, n)) + line["intercept"])
            end
        end


    end

    return JuMP.@objective(pm.model, Min,
        sum(
            sum( _PM.var(pm, n,:pg_cost, i) for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in _PM.nws(pm))
        )
end

##################### TNEP Objective   ###################
function objective_min_cost(pm::_PM.AbstractPowerModel)
        gen_cost = Dict()
        for (n, nw_ref) in _PM.nws(pm)
            for (i,gen) in nw_ref[:gen]
                pg = _PM.var(pm, n, :pg, i)

                if length(gen["cost"]) == 1
                    gen_cost[(n,i)] = gen["cost"][1]
                elseif length(gen["cost"]) == 2
                    gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
                elseif length(gen["cost"]) == 3
                    gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
                else
                    gen_cost[(n,i)] = 0.0
                end
            end
        end
        return JuMP.@objective(pm.model, Min,
                sum(
                sum(conv["cost"]*_PM.var(pm, n, :conv_ne, i) for (i,conv) in nw_ref[:convdc_ne])
                +
                sum(branch["cost"]*_PM.var(pm, n, :branchdc_ne, i) for (i,branch) in nw_ref[:branchdc_ne])
                +
                30*8760/300*sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
                for (n, nw_ref) in _PM.nws(pm)
        ))
end

function objective_min_cost_acdc(pm::_PM.AbstractPowerModel)
        gen_cost = Dict()
        for (n, nw_ref) in _PM.nws(pm)
            for (i,gen) in nw_ref[:gen]
                pg = _PM.var(pm, n, :pg, i)

                if length(gen["cost"]) == 1
                    gen_cost[(n,i)] = gen["cost"][1]
                elseif length(gen["cost"]) == 2
                    gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
                elseif length(gen["cost"]) == 3
                    gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
                else
                    gen_cost[(n,i)] = 0.0
                end
            end
        end

        return JuMP.@objective(pm.model, Min,
            sum(
                sum(conv["cost"]*_PM.var(pm, n, :conv_ne, i) for (i,conv) in nw_ref[:convdc_ne])
                +
                sum(branch["construction_cost"]*_PM.var(pm, n, :branch_ne, i) for (i,branch) in nw_ref[:ne_branch])
                +
                sum(branch["cost"]*_PM.var(pm, n, :branchdc_ne, i) for (i,branch) in nw_ref[:branchdc_ne])
                +
                sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
                for (n, nw_ref) in _PM.nws(pm)
                    )
        )
end


function objective_min_cost_OPF(pm::_PM.AbstractPowerModel)
        base_nws = pm.setting["base_list"]
        cont_nws = pm.setting["Cont_list"]
        Total_sample = pm.setting["Total_sample"]
        curt_gen = pm.setting["curtailed_gen"]
        max_curt = pm.setting["max_curt"]
        year_base = pm.setting["year_base"]
        total_year = pm.setting["total_yr"]
        gen_cost = Dict()
        FFR_cost = Dict()
        FCR_cost = Dict()
        fail_prob = Dict()
        Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0,)
        FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0,)
        FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0,)
        Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, [i in 1:total_year], start = 0, lower_bound = 0,)
        Cont = _PM.var(pm)[:Cont] = JuMP.@variable(pm.model, start = 0, lower_bound = 0,)
        weights = pm.setting["weights"]

        sol_component_value_mod_wonw(pm,   :Gen_cost, Gen_cost)
        sol_component_value_mod_wonw(pm,   :Curt, Curt)
        sol_component_value_mod_wonw(pm,   :FFR_Reserves, FFRReserves)
        sol_component_value_mod_wonw(pm,   :FCR_Reserves, FCRReserves)
        sol_component_value_mod_wonw(pm,   :Cont, Cont)
        for (n, nw_ref) in _PM.nws(pm)
            for (r, reserves) in nw_ref[:reserves]
                FFR_cost[(n,r)] = reserves["Cf"]
                FCR_cost[(n,r)] = reserves["Cg"]
            end
            for (i,gen) in nw_ref[:gen]
                pg = _PM.var(pm, n, :pg, i)
                if length(gen["cost"]) == 1
                    gen_cost[(n,i)] = gen["cost"][1]
                elseif length(gen["cost"]) == 2
                    gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
                elseif length(gen["cost"]) == 3
                    gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
                else
                    gen_cost[(n,i)] = 0.0
                end
            end
        end
        # display(gen_cost)
        # display(base_nws)
        # display(cont_nws)
        Scale = 8760*10 # 5 for no. of gap years between two time steps
        # multiperiod
        JuMP.@constraint(pm.model, Gen_cost == sum(sum(weights[b]*Scale/10^6*gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen]) for b in base_nws) )
        JuMP.@constraint(pm.model, FFRReserves == sum(weights[b]*FFR_cost[(c,2)]*100*Scale/10^6* _PM.var(pm, c, :Pff, 2) for (b,c,br) in cont_nws) )
        JuMP.@constraint(pm.model, FCRReserves ==  sum(weights[b]*FCR_cost[(c,2)]*100*Scale/10^6*_PM.var(pm, c, :Pgg, 2)  for (b,c,br) in cont_nws) )
        # JuMP.@constraint(pm.model, Cont == sum(weights[b]*_PM.ref(pm, b, :branchdc, br)["fail_prob"]*
        #  (Scale/10^6*gen_cost[(c,3)] - Scale/10^6*gen_cost[(b,3)]) for (b,c,br) in cont_nws) )

      curtailment = Dict()
      capacity = Dict()
      for b in base_nws
          for c in curt_gen
            curtailment[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c)) - _PM.var(pm, b, :pg, c)
            capacity[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c))
         end
      end
      display(capacity)
       for y = 1:total_year
              display(JuMP.@constraint(pm.model, Curt[y] == sum(sum(curtailment[(b,c)] for c in curt_gen) for b in year_base[y]) / sum(sum(capacity[(b,c)] for c in curt_gen) for b in year_base[y])  ) )
              JuMP.@constraint(pm.model, Curt[y] <= max_curt)
        end
          # JuMP.@constraint(pm.model, Curt == sum(sum(Scale*curtailment[(b,c)] for c in curt_gen) for b in base_nws) / sum(sum(Scale*capacity[(b,c)] for c in curt_gen) for b in base_nws) )
          # JuMP.@constraint(pm.model, Curt <= max_curt)
          # return  JuMP.@objective(pm.model, Min, Gen_cost + FFRReserves + FCRReserves + Cont)
          return  JuMP.@objective(pm.model, Min,  FFRReserves + FCRReserves)
  end
#
# #

  function sol_component_value_mod_wonw(pm::_PM.AbstractPowerModel, comp_name::Symbol, variables)
      _PM.sol(pm)[comp_name] = variables
  end


function objective_min_cost_OPF_nocl(pm::_PM.AbstractPowerModel)
        base_nws = pm.setting["base_list"]
        cont_nws = pm.setting["Cont_list"]
        Total_sample = pm.setting["Total_sample"]
        curt_gen = pm.setting["curtailed_gen"]
        max_curt = pm.setting["max_curt"]
        year_base = pm.setting["year_base"]
        total_year = pm.setting["total_yr"]

        gen_cost = Dict()
        FFR_cost = Dict()
        FCR_cost = Dict()
        fail_prob = Dict()
        Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Cont = _PM.var(pm)[:Cont]     = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, [i in 1:total_year], start = 0, lower_bound = 0,)

        sol_component_value_mod_wonw(pm,   :Gen_cost, Gen_cost)
        sol_component_value_mod_wonw(pm,   :Curt, Curt)
        sol_component_value_mod_wonw(pm,   :FFR_Reserves, FFRReserves)
        sol_component_value_mod_wonw(pm,   :FCR_Reserves, FCRReserves)
        sol_component_value_mod_wonw(pm,   :Cont, Cont)

        for (n, nw_ref) in _PM.nws(pm)
            for (r, reserves) in nw_ref[:reserves]
                FFR_cost[(n,r)] = reserves["Cf"]
                FCR_cost[(n,r)] = reserves["Cg"]
            end
            for (i,gen) in nw_ref[:gen]
                pg = _PM.var(pm, n, :pg, i)
                if length(gen["cost"]) == 1
                    gen_cost[(n,i)] = gen["cost"][1]
                elseif length(gen["cost"]) == 2
                    gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
                elseif length(gen["cost"]) == 3
                    gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
                else
                    gen_cost[(n,i)] = 0.0
                end
            end
        end


        # display("#####################################cost of conv and branch")

        Scale = 8760/Total_sample*10 # 5 for no. of gap years between two time steps
        # multiperiod
        JuMP.@constraint(pm.model, Gen_cost == sum(sum(Scale/10^6*gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen]) for b in base_nws) )

        display(JuMP.@constraint(pm.model, FFRReserves == sum(FFR_cost[(c,2)]*100*Scale/10^6* _PM.var(pm, c, :Pff, 2) for (b,c,br) in cont_nws) ))

        display(JuMP.@constraint(pm.model, FCRReserves ==  sum(FCR_cost[(c,2)]*100*Scale/10^6*_PM.var(pm, c, :Pgg, 2)  for (b,c,br) in cont_nws) ))

      # JuMP.@constraint(pm.model, Cont == sum(_PM.ref(pm, b, :branchdc, br)["fail_prob"]*
      #               (Scale/10^6*gen_cost[(c,3)] - Scale/10^6*gen_cost[(b,3)]) for (b,c,br) in cont_nws) )

      curtailment = Dict()
      capacity = Dict()

      for b in base_nws
          for c in curt_gen
            curtailment[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c)) - _PM.var(pm, b, :pg, c)
            capacity[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c))
         end
     end
     for y = 1:total_year
            JuMP.@constraint(pm.model, Curt[y] == sum(sum(curtailment[(b,c)] for c in curt_gen) for b in year_base[y]) / sum(sum(capacity[(b,c)] for c in curt_gen) for b in year_base[y])  )
            JuMP.@constraint(pm.model, Curt[y] <= max_curt)
      end

      # display(JuMP.@constraint(pm.model, Curt == sum(sum(Scale*curtailment[(b,c)] for c in curt_gen) for b in base_nws) / sum(sum(Scale*capacity[(b,c)] for c in curt_gen) for b in base_nws) ) )
      # display(JuMP.@constraint(pm.model, Curt <= max_curt))

        # return  JuMP.@objective(pm.model, Min, Gen_cost + FFRReserves + FCRReserves +Cont ) #for validation of TNEP clustering output
        return  JuMP.@objective(pm.model, Min,  FFRReserves + FCRReserves ) #just for OPF problem
end

function objective_min_cost_OPF_nocl_PLdim(pm::_PM.AbstractPowerModel)
        base_nws = pm.setting["base_list"]
        cont_nws = pm.setting["Cont_list"]
        Total_sample = pm.setting["Total_sample"]
        curt_gen = pm.setting["curtailed_gen"]
        max_curt = pm.setting["max_curt"]
        year_base = pm.setting["year_base"]
        total_year = pm.setting["total_yr"]

        gen_cost = Dict()
        FFR_cost = Dict()
        FCR_cost = Dict()
        fail_prob = Dict()
        Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Cont = _PM.var(pm)[:Cont]     = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, [i in 1:total_year], start = 0, lower_bound = 0,)

        sol_component_value_mod_wonw(pm,   :Gen_cost, Gen_cost)
        sol_component_value_mod_wonw(pm,   :Curt, Curt)
        sol_component_value_mod_wonw(pm,   :FFR_Reserves, FFRReserves)
        sol_component_value_mod_wonw(pm,   :FCR_Reserves, FCRReserves)
        sol_component_value_mod_wonw(pm,   :Cont, Cont)

        for (n, nw_ref) in _PM.nws(pm)
            for (r, reserves) in nw_ref[:reserves]
                FFR_cost[(n,r)] = reserves["Cf"]
                FCR_cost[(n,r)] = reserves["Cg"]
            end
            for (i,gen) in nw_ref[:gen]
                pg = _PM.var(pm, n, :pg, i)
                if length(gen["cost"]) == 1
                    gen_cost[(n,i)] = gen["cost"][1]
                elseif length(gen["cost"]) == 2
                    gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
                elseif length(gen["cost"]) == 3
                    gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
                else
                    gen_cost[(n,i)] = 0.0
                end
            end
        end


        # display("#####################################cost of conv and branch")

        Scale = 8760/Total_sample*10 # 5 for no. of gap years between two time steps
        # multiperiod
        JuMP.@constraint(pm.model, Gen_cost == sum(sum(Scale/10^6*gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen]) for b in base_nws) )

        JuMP.@constraint(pm.model, FFRReserves == sum(FFR_cost[(c,2)]*100*Scale/10^6* _PM.var(pm, c, :Pff, 2) for (b,c,br) in cont_nws) )

       JuMP.@constraint(pm.model, FCRReserves ==  sum(FCR_cost[(c,2)]*100*Scale/10^6*_PM.var(pm, c, :Pgg, 2)  for (b,c,br) in cont_nws) )

      # JuMP.@constraint(pm.model, Cont == sum(_PM.ref(pm, b, :branchdc, br)["fail_prob"]*
      #               (Scale/10^6*gen_cost[(c,2)] - Scale/10^6*gen_cost[(b,2)]) for (b,c,br) in cont_nws) )

      curtailment = Dict()
      capacity = Dict()

      for b in base_nws
          for c in curt_gen
            curtailment[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c)) - _PM.var(pm, b, :pg, c)
            capacity[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c))
         end
     end
     for y = 1:total_year
            JuMP.@constraint(pm.model, Curt[y] == sum(sum(curtailment[(b,c)] for c in curt_gen) for b in year_base[y]) / sum(sum(capacity[(b,c)] for c in curt_gen) for b in year_base[y])  )
            JuMP.@constraint(pm.model, Curt[y] <= max_curt)
      end

      # display(JuMP.@constraint(pm.model, Curt == sum(sum(Scale*curtailment[(b,c)] for c in curt_gen) for b in base_nws) / sum(sum(Scale*capacity[(b,c)] for c in curt_gen) for b in base_nws) ) )
      # display(JuMP.@constraint(pm.model, Curt <= max_curt))

        # return  JuMP.@objective(pm.model, Min, Gen_cost + FFRReserves + FCRReserves +Cont ) #for validation of TNEP clustering output
        return  JuMP.@objective(pm.model, Min, FFRReserves + FCRReserves ) #just for OPF problem
end



function objective_min_cost_OPF_sensitivity(pm::_PM.AbstractPowerModel)
        base_nws = pm.setting["base_list"]
        cont_nws = pm.setting["Cont_list"]
        Total_sample = pm.setting["Total_sample"]
        curt_gen = pm.setting["curtailed_gen"]
        max_curt = pm.setting["max_curt"]
        year_base = pm.setting["year_base"]
        total_year = pm.setting["total_yr"]

        gen_cost = Dict()
        FFR_cost = Dict()
        FCR_cost = Dict()
        fail_prob = Dict()
        Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Cont = _PM.var(pm)[:Cont]     = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, [i in 1:total_year], start = 0, lower_bound = 0,)

        sol_component_value_mod_wonw(pm,   :Gen_cost, Gen_cost)
        sol_component_value_mod_wonw(pm,   :Curt, Curt)
        sol_component_value_mod_wonw(pm,   :FFR_Reserves, FFRReserves)
        sol_component_value_mod_wonw(pm,   :FCR_Reserves, FCRReserves)
        sol_component_value_mod_wonw(pm,   :Cont, Cont)

        for (n, nw_ref) in _PM.nws(pm)
            for (r, reserves) in nw_ref[:reserves]
                FFR_cost[(n,r)] = reserves["Cf"]
                FCR_cost[(n,r)] = reserves["Cg"]
            end
            for (i,gen) in nw_ref[:gen]
                pg = _PM.var(pm, n, :pg, i)
                if length(gen["cost"]) == 1
                    gen_cost[(n,i)] = gen["cost"][1]
                elseif length(gen["cost"]) == 2
                    gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
                elseif length(gen["cost"]) == 3
                    gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
                else
                    gen_cost[(n,i)] = 0.0
                end
            end
        end


        # display("#####################################cost of conv and branch")

        Scale = 1 # 5 for no. of gap years between two time steps
        # multiperiod
        display(JuMP.@constraint(pm.model, Gen_cost == sum(sum(Scale/10^6*gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen]) for b in base_nws) ))

        display(JuMP.@constraint(pm.model, FFRReserves == sum(FFR_cost[(c,2)]*100*Scale/10^6* _PM.var(pm, c, :Pff, 2) for (b,c,br) in cont_nws) ))

        display(JuMP.@constraint(pm.model, FCRReserves ==  sum(FCR_cost[(c,2)]*100*Scale/10^6*_PM.var(pm, c, :Pgg, 2)  for (b,c,br) in cont_nws) ))

      # JuMP.@constraint(pm.model, Cont == sum(_PM.ref(pm, b, :branchdc, br)["fail_prob"]*
      #               (Scale/10^6*gen_cost[(c,3)] - Scale/10^6*gen_cost[(b,3)]) for (b,c,br) in cont_nws) )

      curtailment = Dict()
      capacity = Dict()

      for b in base_nws
          for c in curt_gen
            curtailment[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c)) - _PM.var(pm, b, :pg, c)
            capacity[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c))
         end
     end
     display("curtailment_")
     for y = 1:total_year
            display(JuMP.@constraint(pm.model, Curt[y] == sum(sum(curtailment[(b,c)] for c in curt_gen) for b in year_base[y]) / sum(sum(capacity[(b,c)] for c in curt_gen) for b in year_base[y])  ))
            display(JuMP.@constraint(pm.model, Curt[y] <= max_curt))
      end

      # display(JuMP.@constraint(pm.model, Curt == sum(sum(Scale*curtailment[(b,c)] for c in curt_gen) for b in base_nws) / sum(sum(Scale*capacity[(b,c)] for c in curt_gen) for b in base_nws) ) )
      # display(JuMP.@constraint(pm.model, Curt <= max_curt))

        # return  JuMP.@objective(pm.model, Min, Gen_cost + FFRReserves + FCRReserves +Cont ) #for validation of TNEP clustering output
        return  JuMP.@objective(pm.model, Min,  FFRReserves + FCRReserves ) #just for OPF problem
end
