function objective_min_cost_TNEP(pm::_PM.AbstractPowerModel)
    if pm.setting["FSprotection"] == true || pm.setting["NSprotection"] == true
        objective_min_cost_TNEP_FSNS(pm)
    elseif  pm.setting["Permanentloss"] == true
        objective_min_cost_TNEP_PL(pm)
    end
end

function objective_min_cost_TNEP_nocl(pm::_PM.AbstractPowerModel)
    if pm.setting["FSprotection"] == true || pm.setting["NSprotection"] == true
        objective_min_cost_TNEP_FSNS_nocl(pm)
    elseif  pm.setting["Permanentloss"] == true
        objective_min_cost_TNEP_PL_nocl(pm)
    end
end

function objective_min_cost_TNEP_FSNS_nocl(pm::_PM.AbstractPowerModel)
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
        Inv_cost = _PM.var(pm)[:Inv_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Cont = _PM.var(pm)[:Cont]     = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, [i in 1:total_year], start = 0, lower_bound = 0)

        sol_component_value_mod_wonw(pm,   :Inv_cost, Inv_cost)
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

        FFR_list =  Dict()
        FCR_list = Dict()
        for (b,c,br) in cont_nws
            FFR_list[(b,c)] = FFR_cost[(c,2)]*100/10^6*_PM.var(pm, c, :Pff, 2)+
                              FCR_cost[(c,2)]*100/10^6*_PM.var(pm, c, :Pgg, 2)
            # a_ub, a_lb = _IM.variable_domain(_PM.var(pm, c, :Pff, 2))
            # display("a_ub:$a_ub a_lb:$a_lb")
        end

        Zff = _PM.var(pm)[:Zff] = Dict((b, c) => JuMP.@variable(pm.model, base_name = "zff[$(string(b)),$(string(c))]", binary = true, start = 0) for (b, c, br) in cont_nws)
        sol_component_value_mod_wonw(pm, :Zff, Zff)

        #maximum out of onshore converters
        FFRReserves_max = _PM.var(pm)[:FFRReserves_max] = JuMP.@variable(pm.model, [b in base_nws], base_name ="FFRReserves_max", start = 0)
        FCRReserves_max = _PM.var(pm)[:FCRReserves_max] = JuMP.@variable(pm.model, [b in base_nws], base_name ="FCRReserves_max", start = 0)
        for b in base_nws
            sol_component_value_mod(pm, b, :FFRReserves_max, FFRReserves_max[b])
            sol_component_value_mod(pm, b, :FCRReserves_max, FCRReserves_max[b])
        end

        base_cont= Dict()

        for b in base_nws
            # [item for item in a if item[2] == 4]
            base_cont = [tt for tt in cont_nws if tt[1] == b]

            ####_PM.var(pm)[:Zff] = JuMP.@variable(pm.model, [(z,w) in base_cont], base_name="zff", binary = true, start = 0 ) #just one variable, how to create multiple with an index
            for (z,w) in base_cont
            display(JuMP.@constraint(pm.model,  FFRReserves_max[b]  >= FFR_list[(z,w)] ))
            display(JuMP.@constraint(pm.model,  FFRReserves_max[b] <= FFR_list[(z,w)] + 100*(1-Zff[(z,w)])))
            end
            display(JuMP.@constraint(pm.model,  sum(Zff[(z,w)] for (z, w) in base_cont) == 1 ) )
        end

        Scale = 8760*5/Total_sample # 5 for no. of gap years between two time steps
        # multiperiod

		JuMP.@constraint(pm.model, Inv_cost == sum(sum(conv["cost"]*_PM.var(pm, 1, :conv_ne, i) for (i,conv) in _PM.nws(pm)[1][:convdc_ne]) for (n, nw_ref) in _PM.nws(pm)) +
		           sum(sum(branch["cost"]*_PM.var(pm, 1, :branchdc_ne, i) for (i,branch) in _PM.nws(pm)[1][:branchdc_ne]) for (n, nw_ref) in _PM.nws(pm)) )
		JuMP.@constraint(pm.model, Gen_cost == sum(sum(Scale/10^6*gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen]) for b in base_nws) )
		JuMP.@constraint(pm.model, FFRReserves == Scale*sum(FFRReserves_max[b] for b in base_nws) )
		JuMP.@constraint(pm.model, FCRReserves == Scale*sum(FCRReserves_max[b] for b in base_nws) )

		# display(JuMP.@constraint(pm.model, FCRReserves ==  sum(FCR_cost[(c,2)]*100*Scale/10^6*_PM.var(pm, c, :Pgg, 2)  for (b,c,br) in cont_nws) ) )
		display(JuMP.@constraint(pm.model, Cont == sum(_PM.ref(pm, b, :branchdc_ne, br)["fail_prob"]*_PM.var(pm, b, :branchdc_ne, br)*
            	(Scale/10^6*gen_cost[(c,3)] - Scale/10^6*gen_cost[(b,3)]) for (b,c,br) in cont_nws) ) )

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
        return  JuMP.@objective(pm.model, Min, Inv_cost + Gen_cost + FFRReserves + FCRReserves + Cont - Gen_cost)
end

function objective_min_cost_TNEP_FSNS(pm::_PM.AbstractPowerModel)
	display("objective_min_cost_TNEP_FSNS")
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
        Inv_cost = _PM.var(pm)[:Inv_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, start = 0)
        Cont = _PM.var(pm)[:Cont]     = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        weights = pm.setting["weights"]

        sol_component_value_mod_wonw(pm,   :Inv_cost, Inv_cost)
        sol_component_value_mod_wonw(pm,   :Gen_cost, Gen_cost)
		sol_component_value_mod_wonw(pm,   :FFR_Reserves, FFRReserves)
        sol_component_value_mod_wonw(pm,   :FCR_Reserves, FCRReserves)
        sol_component_value_mod_wonw(pm,   :Cont, Cont)
		sol_component_value_mod_wonw(pm,   :Curt, Curt)

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


        FFR_list =  Dict()
        FCR_list = Dict()
        for (b,c,br) in cont_nws
            FFR_list[(b,c)] = FFR_cost[(c,2)]*100/10^6*_PM.var(pm, c, :Pff, 2)+
                              FCR_cost[(c,2)]*100/10^6*_PM.var(pm, c, :Pgg, 2)
            # a_ub, a_lb = _IM.variable_domain(_PM.var(pm, c, :Pff, 2))
            # display("a_ub:$a_ub a_lb:$a_lb")
        end
        Zff = _PM.var(pm)[:Zff] = Dict((b, c) => JuMP.@variable(pm.model, base_name = "zff[$(string(b)),$(string(c))]", binary = true, start = 0) for (b, c, br) in cont_nws)
        sol_component_value_mod_wonw(pm, :Zff, Zff)
        # _IM.sol_component_value(pm, nw, :reserves, :Zff, base_nws, Zff)
        FFRReserves_max = _PM.var(pm)[:FFRReserves_max] = JuMP.@variable(pm.model, [b in base_nws], base_name ="FFRReserves_max", start = 0)
        FCRReserves_max = _PM.var(pm)[:FCRReserves_max] = JuMP.@variable(pm.model, [b in base_nws], base_name ="FCRReserves_max", start = 0)
        for b in base_nws
            sol_component_value_mod(pm, b, :FFRReserves_max, FFRReserves_max[b])
            sol_component_value_mod(pm, b, :FCRReserves_max, FCRReserves_max[b])
        end
        base_cont= Dict()
        for b in base_nws
            # [item for item in a if item[2] == 4]
            base_cont = [tt for tt in cont_nws if tt[1] == b]

            ####_PM.var(pm)[:Zff] = JuMP.@variable(pm.model, [(z,w) in base_cont], base_name="zff", binary = true, start = 0 ) #just one variable, how to create multiple with an index
            for (z,w) in base_cont
            JuMP.@constraint(pm.model,  FFRReserves_max[b] >= FFR_list[(z,w)] )
            JuMP.@constraint(pm.model,  FFRReserves_max[b] <= FFR_list[(z,w)] + 100*(1-Zff[(z,w)]))
            end
            JuMP.@constraint(pm.model,  sum(Zff[(z,w)] for (z, w) in base_cont) == 1 )
        end

        Scale = 8760*10  # 5 for no. of gap years between two time steps

            # for (i,branch) in _PM.nws(pm)[1][:branchdc_ne]
            #     display(branch["cost"])
            #  end
            #
            #  for (i,conv) in _PM.nws(pm)[1][:convdc_ne]
            #      display(conv["cost"])
            #   end
            # display(gen_cost)

            JuMP.@constraint(pm.model, Inv_cost == sum(sum(conv["cost"]*_PM.var(pm, 1, :conv_ne, i) for (i,conv) in _PM.nws(pm)[1][:convdc_ne]) for (n, nw_ref) in _PM.nws(pm)) +
                       sum(sum(branch["cost"]*_PM.var(pm, 1, :branchdc_ne, i) for (i,branch) in _PM.nws(pm)[1][:branchdc_ne]) for (n, nw_ref) in _PM.nws(pm)) )
			JuMP.@constraint(pm.model, Gen_cost == sum(weights[b]*sum(Scale/10^6*gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen]) for b in base_nws) )
			# display(JuMP.@constraint(pm.model, FFRReserves == sum(FFR_cost[(c,2)]*100*Scale/10^6* _PM.var(pm, c, :Pff, 2) for (b,c,br) in cont_nws) ))
            JuMP.@constraint(pm.model, FFRReserves == Scale*sum(weights[b]*FFRReserves_max[b] for b in base_nws) )
            JuMP.@constraint(pm.model, FCRReserves == Scale*sum(weights[b]*FCRReserves_max[b] for b in base_nws) )

			# display(JuMP.@constraint(pm.model, FCRReserves ==  sum(FCR_cost[(c,2)]*100*Scale/10^6*_PM.var(pm, c, :Pgg, 2)  for (b,c,br) in cont_nws) ) )
			# print(JuMP.@constraint(pm.model, Cont == sum( sum( (Scale/10^6) *gen_cost[(c,i)]*_PM.ref(pm, b, :branchdc_ne, br)["fail_prob"]*_PM.var(pm, 1, :branchdc_ne, br)
            #         for i in  curt_gen)
            #         for (b,c,br) in cont_nws) ) )

            # display(JuMP.@constraint(pm.model, Cont == sum(weights[b]*_PM.ref(pm, b, :branchdc_ne, br)["fail_prob"]*_PM.var(pm, b, :branchdc_ne, br)*
            # (Scale/10^6*gen_cost[(c,3)] - Scale/10^6*gen_cost[(b,3)]) for (b,c,br) in cont_nws) ) )
 			curtailment = Dict()
			capacity = Dict()
			#
			#  for b in base_nws
			# 	  for c in curt_gen
			# 		curtailment[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c)) - _PM.var(pm, b, :pg, c)
            #         # curtailment[(b,c)] = _PM.var(pm, b, :pg, c)
			# 		capacity[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c))
			# 	 end
			#  end
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
	               # JuMP.@constraint(pm.model, Curt[y] <= max_curt)
	        end
            return JuMP.@objective(pm.model, Min, Inv_cost + FFRReserves + FCRReserves + Gen_cost )
end

function objective_min_cost_TNEP_PL_nocl(pm::_PM.AbstractPowerModel)
	base_nws = pm.setting["base_list"]
	cont_nws = pm.setting["Cont_list"]
	Total_sample = pm.setting["Total_sample"]
	curt_gen = pm.setting["curtailed_gen"]
	max_curt = pm.setting["max_curt"]
	year_base = pm.setting["year_base"]
	total_year = pm.setting["total_yr"]
	weights = pm.setting["weights"]

	gen_cost = Dict()
	FFR_cost = Dict()
	FCR_cost = Dict()
	fail_prob = Dict()
	Inv_cost = _PM.var(pm)[:Inv_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
	Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
	FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
	FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
	Cont = _PM.var(pm)[:Cont]     = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
	Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, [i in 1:total_year], start = 0, lower_bound = 0)

	sol_component_value_mod_wonw(pm,   :Inv_cost, Inv_cost)
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

	Scale = 8760/Total_sample*5 # 5 for no. of gap years between two time steps

	JuMP.@constraint(pm.model, Inv_cost == sum(sum(conv["cost"]*_PM.var(pm, 1, :conv_ne, i) for (i,conv) in _PM.nws(pm)[1][:convdc_ne]) for (n, nw_ref) in _PM.nws(pm)) +
			   sum(sum(branch["cost"]*_PM.var(pm, 1, :branchdc_ne, i) for (i,branch) in _PM.nws(pm)[1][:branchdc_ne]) for (n, nw_ref) in _PM.nws(pm)) )
	JuMP.@constraint(pm.model, Gen_cost == sum(sum(Scale/10^6*gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen]) for b in base_nws) )
	JuMP.@constraint(pm.model, FFRReserves == sum(FFR_cost[(c,2)]*100*Scale/10^6* _PM.var(pm, c, :Pff, 2) for (b,c,br) in cont_nws) )
	JuMP.@constraint(pm.model, FCRReserves ==  sum(FCR_cost[(c,2)]*100*Scale/10^6*_PM.var(pm, c, :Pgg, 2)  for (b,c,br) in cont_nws) )
	JuMP.@constraint(pm.model, Cont == sum(_PM.ref(pm, b, :branchdc_ne, br)["fail_prob"]*_PM.var(pm, b, :branchdc_ne, br)*
	(Scale/10^6*gen_cost[(c,3)] - Scale/10^6*gen_cost[(b,3)]) for (b,c,br) in cont_nws) )
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
	        # JuMP.@constraint(pm.model, Curt[y] <= max_curt)
	  end

	return display( JuMP.@objective(pm.model, Min, Inv_cost + Gen_cost + FFRReserves + FCRReserves + Cont  ) )
end

function objective_min_cost_TNEP_PL(pm::_PM.AbstractPowerModel)
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
        Inv_cost = _PM.var(pm)[:Inv_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, start = 0)
        Cont = _PM.var(pm)[:Cont]     = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        weights = pm.setting["weights"]

        sol_component_value_mod_wonw(pm,   :Inv_cost, Inv_cost)
        sol_component_value_mod_wonw(pm,   :Gen_cost, Gen_cost)
		sol_component_value_mod_wonw(pm,   :FFR_Reserves, FFRReserves)
        sol_component_value_mod_wonw(pm,   :FCR_Reserves, FCRReserves)
        sol_component_value_mod_wonw(pm,   :Cont, Cont)
		sol_component_value_mod_wonw(pm,   :Curt, Curt)

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


        FFR_list =  Dict()
        FCR_list = Dict()
        for (b,c,br) in cont_nws
            FFR_list[(b,c)] = FFR_cost[(c,2)]*100/10^6*_PM.var(pm, c, :Pff, 2)+
                              FCR_cost[(c,2)]*100/10^6*_PM.var(pm, c, :Pgg, 2)
            # a_ub, a_lb = _IM.variable_domain(_PM.var(pm, c, :Pff, 2))
            # display("a_ub:$a_ub a_lb:$a_lb")
        end
        Zff = _PM.var(pm)[:Zff] = Dict((b, c) => JuMP.@variable(pm.model, base_name = "zff[$(string(b)),$(string(c))]", binary = true, start = 0) for (b, c, br) in cont_nws)
        sol_component_value_mod_wonw(pm, :Zff, Zff)
        # _IM.sol_component_value(pm, nw, :reserves, :Zff, base_nws, Zff)
        FFRReserves_max = _PM.var(pm)[:FFRReserves_max] = JuMP.@variable(pm.model, [b in base_nws], base_name ="FFRReserves_max", start = 0)
        FCRReserves_max = _PM.var(pm)[:FCRReserves_max] = JuMP.@variable(pm.model, [b in base_nws], base_name ="FCRReserves_max", start = 0)
        for b in base_nws
            sol_component_value_mod(pm, b, :FFRReserves_max, FFRReserves_max[b])
            sol_component_value_mod(pm, b, :FCRReserves_max, FCRReserves_max[b])
        end
        base_cont= Dict()
        for b in base_nws
            # [item for item in a if item[2] == 4]
            base_cont = [tt for tt in cont_nws if tt[1] == b]

            ####_PM.var(pm)[:Zff] = JuMP.@variable(pm.model, [(z,w) in base_cont], base_name="zff", binary = true, start = 0 ) #just one variable, how to create multiple with an index
            for (z,w) in base_cont
            JuMP.@constraint(pm.model,  FFRReserves_max[b] >= FFR_list[(z,w)] )
            JuMP.@constraint(pm.model,  FFRReserves_max[b] <= FFR_list[(z,w)] + 100*(1-Zff[(z,w)]))
            end
            JuMP.@constraint(pm.model,  sum(Zff[(z,w)] for (z, w) in base_cont) == 1 )
        end

        Scale = 8760*10  # 5 for no. of gap years between two time steps

            # for (i,branch) in _PM.nws(pm)[1][:branchdc_ne]
            #     display(branch["cost"])
            #  end
            #
            #  for (i,conv) in _PM.nws(pm)[1][:convdc_ne]
            #      display(conv["cost"])
            #   end
            # display(gen_cost)

            JuMP.@constraint(pm.model, Inv_cost == sum(sum(conv["cost"]*_PM.var(pm, 1, :conv_ne, i) for (i,conv) in _PM.nws(pm)[1][:convdc_ne]) for (n, nw_ref) in _PM.nws(pm)) +
                       sum(sum(branch["cost"]*_PM.var(pm, 1, :branchdc_ne, i) for (i,branch) in _PM.nws(pm)[1][:branchdc_ne]) for (n, nw_ref) in _PM.nws(pm)) )
			JuMP.@constraint(pm.model, Gen_cost == sum(weights[b]*sum(Scale/10^6*gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen]) for b in base_nws) )
			# display(JuMP.@constraint(pm.model, FFRReserves == sum(FFR_cost[(c,2)]*100*Scale/10^6* _PM.var(pm, c, :Pff, 2) for (b,c,br) in cont_nws) ))
            JuMP.@constraint(pm.model, FFRReserves == Scale*sum(weights[b]*FFRReserves_max[b] for b in base_nws) )
            JuMP.@constraint(pm.model, FCRReserves == Scale*sum(weights[b]*FCRReserves_max[b] for b in base_nws) )

			# display(JuMP.@constraint(pm.model, FCRReserves ==  sum(FCR_cost[(c,2)]*100*Scale/10^6*_PM.var(pm, c, :Pgg, 2)  for (b,c,br) in cont_nws) ) )
			# print(JuMP.@constraint(pm.model, Cont == sum( sum( (Scale/10^6) *gen_cost[(c,i)]*_PM.ref(pm, b, :branchdc_ne, br)["fail_prob"]*_PM.var(pm, 1, :branchdc_ne, br)
            #         for i in  curt_gen)
            #         for (b,c,br) in cont_nws) ) )

            # display(JuMP.@constraint(pm.model, Cont == sum(weights[b]*_PM.ref(pm, b, :branchdc_ne, br)["fail_prob"]*_PM.var(pm, b, :branchdc_ne, br)*
            # (Scale/10^6*gen_cost[(c,3)] - Scale/10^6*gen_cost[(b,3)]) for (b,c,br) in cont_nws) ) )``
 			curtailment = Dict()
			capacity = Dict()
			#
			#  for b in base_nws
			# 	  for c in curt_gen
			# 		curtailment[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c)) - _PM.var(pm, b, :pg, c)
            #         # curtailment[(b,c)] = _PM.var(pm, b, :pg, c)
			# 		capacity[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c))
			# 	 end
			#  end
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
	               # JuMP.@constraint(pm.model, Curt[y] <= max_curt)
	        end

	return display( JuMP.@objective(pm.model, Min, Inv_cost + Gen_cost + FFRReserves + FCRReserves) )
end


function objective_min_cost_TNEP_FSNS_rev1(pm::_PM.AbstractPowerModel)
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
        Inv_cost = _PM.var(pm)[:Inv_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Gen_cost = _PM.var(pm)[:Gen_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FFRReserves = _PM.var(pm)[:FFR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        FCRReserves = _PM.var(pm)[:FCR_Reserves] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Curt = _PM.var(pm)[:curt] = JuMP.@variable(pm.model, start = 0)
        Cont = _PM.var(pm)[:Cont]     = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        weights = pm.setting["weights"]

        sol_component_value_mod_wonw(pm,   :Inv_cost, Inv_cost)
        sol_component_value_mod_wonw(pm,   :Gen_cost, Gen_cost)
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


        FFR_list =  Dict()
        FCR_list = Dict()
        for (b,c,br) in cont_nws
            FFR_list[(b,c)] = FFR_cost[(c,2)]*100/10^6*_PM.var(pm, c, :Pff, 2)+
                              FCR_cost[(c,2)]*100/10^6*_PM.var(pm, c, :Pgg, 2)
            # a_ub, a_lb = _IM.variable_domain(_PM.var(pm, c, :Pff, 2))
            # display("a_ub:$a_ub a_lb:$a_lb")
        end
        Zff = _PM.var(pm)[:Zff] = Dict((b, c) => JuMP.@variable(pm.model, base_name = "zff[$(string(b)),$(string(c))]", binary = true, start = 0) for (b, c, br) in cont_nws)
        sol_component_value_mod_wonw(pm, :Zff, Zff)
        # _IM.sol_component_value(pm, nw, :reserves, :Zff, base_nws, Zff)
        FFRReserves_max = _PM.var(pm)[:FFRReserves_max] = JuMP.@variable(pm.model, [b in base_nws], base_name ="FFRReserves_max", start = 0)
        FCRReserves_max = _PM.var(pm)[:FCRReserves_max] = JuMP.@variable(pm.model, [b in base_nws], base_name ="FCRReserves_max", start = 0)
        for b in base_nws
            sol_component_value_mod(pm, b, :FFRReserves_max, FFRReserves_max[b])
            sol_component_value_mod(pm, b, :FCRReserves_max, FCRReserves_max[b])
        end
        base_cont= Dict()
        for b in base_nws
            # [item for item in a if item[2] == 4]
            base_cont = [tt for tt in cont_nws if tt[1] == b]

            ####_PM.var(pm)[:Zff] = JuMP.@variable(pm.model, [(z,w) in base_cont], base_name="zff", binary = true, start = 0 ) #just one variable, how to create multiple with an index
            for (z,w) in base_cont
            JuMP.@constraint(pm.model,  FFRReserves_max[b]  >= FFR_list[(z,w)] )
            JuMP.@constraint(pm.model,  FFRReserves_max[b] <= FFR_list[(z,w)] + 100*(1-Zff[(z,w)]))
            end
            JuMP.@constraint(pm.model,  sum(Zff[(z,w)] for (z, w) in base_cont) == 1 )
        end

        Scale = 8760*10  # 5 for no. of gap years between two time steps

            JuMP.@constraint(pm.model, Inv_cost == sum(sum(conv["cost"]*_PM.var(pm, 1, :conv_ne, i) for (i,conv) in _PM.nws(pm)[1][:convdc_ne]) for (n, nw_ref) in _PM.nws(pm)) +
                       sum(sum(branch["cost"]*_PM.var(pm, 1, :branchdc_ne, i) for (i,branch) in _PM.nws(pm)[1][:branchdc_ne]) for (n, nw_ref) in _PM.nws(pm)) )
			display(JuMP.@constraint(pm.model, Gen_cost == sum(weights[b]*sum(Scale/10^6*gen_cost[(b,i)] for i in curt_gen) for b in base_nws) ) )
			# display(JuMP.@constraint(pm.model, FFRReserves == sum(FFR_cost[(c,2)]*100*Scale/10^6* _PM.var(pm, c, :Pff, 2) for (b,c,br) in cont_nws) ))
            JuMP.@constraint(pm.model, FFRReserves == Scale*sum(weights[b]*FFRReserves_max[b] for b in base_nws) )
            JuMP.@constraint(pm.model, FCRReserves == Scale*sum(weights[b]*FCRReserves_max[b] for b in base_nws) )

            # JuMP.@constraint(pm.model, Cont == sum(weights[b]*_PM.ref(pm, b, :branchdc_ne, br)["fail_prob"]*_PM.var(pm, b, :branchdc_ne, br)*
            # (Scale/10^6*(gen_cost[(c,1)] + gen_cost[(c,2)]) - Scale/10^6*(gen_cost[(b,1)]+gen_cost[(b,2)]) ]) for (b,c,br) in cont_nws) )

			curtailment = Dict()
			capacity = Dict()

			 # for b in base_nws
				#   for c in curt_gen
				# 	curtailment[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c)) - _PM.var(pm, b, :pg, c)
             #        # curtailment[(b,c)] = _PM.var(pm, b, :pg, c)
				# 	capacity[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c))
				#  end
			 # end
			 # curtailment = Dict()
	         # capacity = Dict()

	        #  for b in base_nws
	        #      for c in curt_gen
	        #        curtailment[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c)) - _PM.var(pm, b, :pg, c)
	        #        capacity[(b,c)] = JuMP.upper_bound(_PM.var(pm, b, :pg, c))
	        #     end
	        # end
	        # for y = 1:total_year
	        #        JuMP.@constraint(pm.model, Curt[y] == sum(sum(curtailment[(b,c)] for c in curt_gen) for b in year_base[y]) / sum(sum(capacity[(b,c)] for c in curt_gen) for b in year_base[y])  )
	        #        JuMP.@constraint(pm.model, Curt[y] <= max_curt)
	        #  end
			 display("objective_min_cost_TNEP_FSNS_rev1")
            return JuMP.@objective(pm.model, Min,  FFRReserves + FCRReserves + Inv_cost  - Gen_cost)
end
