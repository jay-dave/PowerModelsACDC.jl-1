export run_acdcscopf

""
function run_acdcscopf(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_acdcscopf(data, model_type, solver; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function run_acdcscopf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.run_model(data, model_type, solver, post_acdcscopf; ref_extensions = [add_ref_dcgrid!], kwargs...)
    # return PowerModels.optimize_model!(pm, solver; solution_builder = get_solution_acdc)
end
""
function run_acdcscopf_nocl(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_acdcscopf(data, model_type, solver; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function run_acdcscopf_nocl(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.run_model(data, model_type, solver, post_acdcscopf_nocl; ref_extensions = [add_ref_dcgrid!], kwargs...)
    # return PowerModels.optimize_model!(pm, solver; solution_builder = get_solution_acdc)
end




""
function post_acdcscopf(pm::_PM.AbstractPowerModel)

     for (n, networks) in pm.ref[:nw]
    _PM.variable_bus_voltage(pm; nw = n)
    _PM.variable_gen_power(pm; nw = n)
    _PM.variable_branch_power(pm; nw = n)

    variable_active_dcbranch_flow(pm; nw = n)
    variable_dcbranch_current(pm; nw = n)
    variable_dc_converter(pm; nw = n)
    variable_dcgrid_voltage_magnitude(pm; nw = n)
    variable_frequency_stab(pm; nw = n)
    end

    # for (n, networks) in pm.ref[:nw]
    objective_min_cost_OPF(pm)
    # end

    for (n, networks) in pm.ref[:nw]
    _PM.constraint_model_voltage(pm; nw = n)
    constraint_voltage_dc(pm; nw = n)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i; nw = n)
    end


    for i in _PM.ids(pm, :bus)
        constraint_power_balance_ac(pm, i; nw = n)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i; nw = n)
        _PM.constraint_ohms_yt_to(pm, i; nw = n)
        _PM.constraint_voltage_angle_difference(pm, i; nw = n) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i; nw = n)
        _PM.constraint_thermal_limit_to(pm, i; nw = n)
    end

    for i in _PM.ids(pm, :busdc)
        constraint_power_balance_dc(pm, i; nw = n)
    end
    for i in _PM.ids(pm, nw = n, :branchdc)
        constraint_ohms_dc_branch(pm, i; nw = n)
    end
    for i in _PM.ids(pm, :convdc)
        constraint_converter_losses(pm, i; nw = n)
        constraint_converter_current(pm, i; nw = n)
        constraint_conv_transformer(pm, i; nw = n)
        constraint_conv_reactor(pm, i; nw = n)
        constraint_conv_filter(pm, i; nw = n)
        if pm.ref[:nw][pm.cnw][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i; nw = n)
        end
    end
 end
     constraint_frequency_stab_OPF(pm)
end

function post_acdcscopf_nocl(pm::_PM.AbstractPowerModel)

     for (n, networks) in pm.ref[:nw]
    _PM.variable_bus_voltage(pm; nw = n)
    _PM.variable_gen_power(pm; nw = n)
    _PM.variable_branch_power(pm; nw = n)

    variable_active_dcbranch_flow(pm; nw = n)
    variable_dcbranch_current(pm; nw = n)
    variable_dc_converter(pm; nw = n)
    variable_dcgrid_voltage_magnitude(pm; nw = n)
    variable_frequency_stab(pm; nw = n)
    end

    # for (n, networks) in pm.ref[:nw]
    objective_min_cost_OPF_nocl(pm)
    # end

    for (n, networks) in pm.ref[:nw]
    _PM.constraint_model_voltage(pm; nw = n)
    constraint_voltage_dc(pm; nw = n)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i; nw = n)
    end


    for i in _PM.ids(pm, :bus)
        constraint_power_balance_ac(pm, i; nw = n)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i; nw = n)
        _PM.constraint_ohms_yt_to(pm, i; nw = n)
        _PM.constraint_voltage_angle_difference(pm, i; nw = n) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i; nw = n)
        _PM.constraint_thermal_limit_to(pm, i; nw = n)
    end

    for i in _PM.ids(pm, :busdc)
        constraint_power_balance_dc(pm, i; nw = n)
    end
    for i in _PM.ids(pm, nw = n, :branchdc)
        constraint_ohms_dc_branch(pm, i; nw = n)
    end
    for i in _PM.ids(pm, :convdc)
        constraint_converter_losses(pm, i; nw = n)
        constraint_converter_current(pm, i; nw = n)
        constraint_conv_transformer(pm, i; nw = n)
        constraint_conv_reactor(pm, i; nw = n)
        constraint_conv_filter(pm, i; nw = n)
        if pm.ref[:nw][pm.cnw][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i; nw = n)
        end
    end
 end
     constraint_frequency_stab_OPF(pm)
end
