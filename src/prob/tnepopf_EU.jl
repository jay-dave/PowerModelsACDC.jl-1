export tnepopf_EU

""
function tnepopf_EU(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    return tnepopf_EU(data, model_type, solver; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!], kwargs...)
end

""
function tnepopf_EU(data::Dict{String,Any}, model_type::Type, solver; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!], setting = s, kwargs...)
    if setting["process_data_internally"] == true
        # PowerModelsACDC.process_additional_data!(data)
        process_additional_data!(data)
    end
    s = setting
    return _PM.run_model(data, model_type, solver, post_tnepopf_EU; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!], setting = s, kwargs...)
    # pm = _PM.build_model(data, model_type, post_tnepopf_EU; setting = s, kwargs...)
    # return _PM.optimize_model!(pm, solver; solution_builder = get_solution_acdc_ne)
end

""
function post_tnepopf_EU(pm::_PM.AbstractPowerModel)
    # for (n, networks) in pm.ref[:nw]
    #     PowerModelsACDC.add_ref_dcgrid!(pm, n)
    #     add_candidate_dcgrid!(pm, n)
    # end
    for (n, networks) in pm.ref[:nw]
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        variable_voltage_slack(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        # new variables for TNEP problem
        variable_active_dcbranch_flow_ne(pm; nw = n)
        variable_branch_ne(pm; nw = n)
        variable_dc_converter_ne(pm; nw = n) # add more variables in variableconv.jl
        variable_dcbranch_current_ne(pm; nw = n)
        variable_dcgrid_voltage_magnitude_ne(pm; nw = n)
        # variable_load_shedding_real(pm; nw = n)

    end
    objective_min_cost_EU(pm)
    for (n, networks) in pm.ref[:nw]
        _PM.constraint_model_voltage(pm; nw = n)
        constraint_voltage_dc(pm)
        constraint_voltage_dc_ne(pm)
        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i, nw = n)
        end

        for i in _PM.ids(pm, n, :bus)
            constraint_power_balance_ac_dcne(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branch)
            _PM.constraint_ohms_yt_from_EU(pm, i; nw = n)
            _PM.constraint_ohms_yt_to_EU(pm, i; nw = n)
            _PM.constraint_voltage_angle_difference(pm, i; nw = n)
            _PM.constraint_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_thermal_limit_to(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :busdc)
            constraint_power_balance_dc_dcne(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :busdc_ne)
            constraint_power_balance_dcne_dcne(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branchdc)
            PowerModelsACDC.constraint_ohms_dc_branch(pm, i; nw = n)
        end
        for i in _PM.ids(pm, :branchdc_ne)
            constraint_ohms_dc_branch_ne(pm, i; nw = n)
            constraint_branch_limit_on_off(pm, i; nw = n)
            if n > 1
                constraint_candidate_dcbranches_mp(pm, n, i)
            end
        end

        for i in _PM.ids(pm, :convdc)
            constraint_converter_losses(pm, i; nw = n)
            constraint_converter_current(pm, i; nw = n)
            constraint_conv_transformer(pm, i; nw = n)
            constraint_conv_reactor(pm, i; nw = n)
            constraint_conv_filter(pm, i; nw = n)
            if pm.ref[:nw][n][:convdc][i]["islcc"] == 1
                constraint_conv_firing_angle(pm, i; nw = n)
            end
        end
        for i in _PM.ids(pm, n, :convdc_ne)
            constraint_converter_losses_ne(pm, i; nw = n)
            constraint_converter_current_ne(pm, i; nw = n)
            constraint_converter_limit_on_off(pm, i; nw = n)
            if n > 1
                constraint_candidate_converters_mp(pm, n, i)
            end
            constraint_conv_transformer_ne(pm, i; nw = n)
            constraint_conv_reactor_ne(pm, i; nw = n)
            constraint_conv_filter_ne(pm, i; nw = n)
            #display(pm.ref)
            if pm.ref[:nw][n][:convdc_ne][i]["islcc"] == 1
                constraint_conv_firing_angle_ne(pm, i; nw = n)
            end
        end
    end
end


function objective_min_cost_EU(pm::_PM.AbstractPowerModel)
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
        Gen_cost_p1 = _PM.var(pm)[:Gen_cost1] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Gen_cost_p2 = _PM.var(pm)[:Gen_cost2] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Gen_cost_p3 = _PM.var(pm)[:Gen_cost3] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Inv_cost = _PM.var(pm)[:Inv_cost] = JuMP.@variable(pm.model, start = 0, lower_bound = 0)
        Gen_cost_p1 =   sum( 10*8760/500*sum( gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen] ) for b in 1:500)
        Gen_cost_p2 =   1/(1+0.05)^10*sum( 10*8760/500*sum( gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen] ) for b in 501:1000)
        Gen_cost_p3 =   1/(1+0.05)^20*sum( 10*8760/500*sum( gen_cost[(b,i)] for (i,gen) in _PM.nws(pm)[b][:gen] ) for b in 1001:1500)
        Inv_cost =      sum(sum(conv["cost"]*_PM.var(pm, n, :conv_ne, i) for (i,conv) in nw_ref[:convdc_ne])
                        +
                        sum(branch["cost"]*_PM.var(pm, n, :branchdc_ne, i) for (i,branch) in nw_ref[:branchdc_ne])
                        for (n, nw_ref) in _PM.nws(pm)
                            )

        return JuMP.@objective(pm.model, Min, Gen_cost_p1 + Gen_cost_p2 + Gen_cost_p3 + Inv_cost)
end


# function variable_load_shedding_real(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
#     pdl = _PM.var(pm, nw)[:pdl] = JuMP.@variable(pm.model,
#         [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_pdl",
#         start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "pdl_start")
#     )
#
#     if bounded
#         for (b, bus) in _PM.ref(pm, nw, :bus)
#             JuMP.set_lower_bound(pdl[b], 0)
#
#             bus_loads = PowerModels.ref(pm, nw, :bus_loads, b)
#             display("b:$b")
#             pd_max = sum(PowerModels.ref(pm, nw, :load, k, "pd") for k in bus_loads)
#             JuMP.set_upper_bound(pdl[b], pd_max)
#         end
#     end
#
#     report && _IM.sol_component_value(pm, nw, :bus, :pld, _PM.ids(pm, nw, :bus), pdl)
# end


# function constraint_power_balance_ac_dcne_ls(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     bus = PowerModels.ref(pm, nw, :bus, i)
#     bus_arcs = PowerModels.ref(pm, nw, :bus_arcs, i)
#     bus_arcs_dc = PowerModels.ref(pm, nw, :bus_arcs_dc, i)
#     bus_gens = PowerModels.ref(pm, nw, :bus_gens, i)
#     bus_convs_ac = PowerModels.ref(pm, nw, :bus_convs_ac, i)
#     bus_convs_ac_ne = PowerModels.ref(pm, nw, :bus_convs_ac_ne, i)
#     bus_loads = PowerModels.ref(pm, nw, :bus_loads, i)
#     bus_shunts = PowerModels.ref(pm, nw, :bus_shunts, i)
#
#     pd = Dict(k => PowerModels.ref(pm, nw, :load, k, "pd") for k in bus_loads)
#     qd = Dict(k => PowerModels.ref(pm, nw, :load, k, "qd") for k in bus_loads)
#
#     gs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
#     bs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)
#     constraint_power_balance_ac_dcne_ls(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, pd, qd, gs, bs)
# end
#
# function constraint_power_balance_ac_dcne_ls(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, pd, qd, gs, bs)
#     p = _PM.var(pm, n, :p)
#     pg = _PM.var(pm, n, :pg)
#     pdl = _PM.var(pm, n, :pdl)
#     pconv_grid_ac_ne = _PM.var(pm, n, :pconv_tf_fr_ne)
#     pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
#     pconv_ac = _PM.var(pm, n, :pconv_ac)
#     pconv_ac_ne = _PM.var(pm, n, :pconv_ac_ne)
#     v = 1
#     display("constraint_power_balance_ac_dcne")
#     display(JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) + pd[i] - sum(gs[s] for s in bus_shunts)*v^2) )
# end


# function objective_min_cost_EU(pm::_PM.AbstractPowerModel)
#         gen_cost = Dict()
#         for (n, nw_ref) in _PM.nws(pm)
#             for (i,gen) in nw_ref[:gen]
#                 pg = _PM.var(pm, n, :pg, i)
#
#                 if length(gen["cost"]) == 1
#                     gen_cost[(n,i)] = gen["cost"][1]
#                 elseif length(gen["cost"]) == 2
#                     gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
#                 elseif length(gen["cost"]) == 3
#                     gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
#                 else
#                     gen_cost[(n,i)] = 0.0
#                 end
#             end
#         end
#
#         return JuMP.@objective(pm.model, Min,
#             sum(
#                 sum(conv["cost"]*_PM.var(pm, n, :conv_ne, i) for (i,conv) in nw_ref[:convdc_ne])
#                 +
#                 sum(branch["cost"]*_PM.var(pm, n, :branchdc_ne, i) for (i,branch) in nw_ref[:branchdc_ne])
#                 +
#                 10*8760/500*sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
#                 for (n, nw_ref) in _PM.nws(pm)
#                     )
#         )
# end
