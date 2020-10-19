function variable_frequency_stab(pm::_PM.AbstractPowerModel; kwargs...)
    variable_frequency_reserves(pm; kwargs...)
    variable_frequency_reserves_bin(pm; kwargs...)
    variable_frequency_power_dev(pm; kwargs...)
    variable_frequency_power_dev_aux(pm; kwargs...)
end

function variable_frequency_stab_ne(pm::_PM.AbstractPowerModel; kwargs...)
    variable_frequency_reserves_ne(pm; kwargs...)
    variable_frequency_reserves_bin_ne(pm; kwargs...)
    variable_frequency_power_dev_ne(pm; kwargs...)
    variable_frequency_power_dev_aux_ne(pm; kwargs...)
end


function variable_frequency_reserves(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bi_bp = Dict([((reserves["syncarea"]),i ) for (i,reserves) in _PM.ref(pm, nw, :reserves)])
    reserves = _PM.ref(pm, nw, :reserves)
    Pg = _PM.var(pm, nw)[:Pgg] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_pgg",
    lower_bound = 0, upper_bound = reserves[bi_bp[i]]["Pgmax"], start = 0)

    Pf = _PM.var(pm, nw)[:Pff] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_pff",
    lower_bound = 0, upper_bound = reserves[bi_bp[i]]["Pfmax"], start = 0)

    report && _IM.sol_component_value(pm, nw, :reserves, :Pgg, _PM.ids(pm, nw, :arcs_reserves_syn), Pg)
    report && _IM.sol_component_value(pm, nw, :reserves, :Pff, _PM.ids(pm, nw, :arcs_reserves_syn), Pf)
end

function variable_frequency_reserves_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bi_bp = Dict([((reserves["syncarea"]),i ) for (i,reserves) in _PM.ref(pm, nw, :reserves)])
    reserves = _PM.ref(pm, nw, :reserves)
    Pg = _PM.var(pm, nw)[:Pgg] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_pgg",
    lower_bound = 0, upper_bound = reserves[bi_bp[i]]["Pgmax"], start = 0)

    Pf = _PM.var(pm, nw)[:Pff] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_pff",
    lower_bound = 0, upper_bound = reserves[bi_bp[i]]["Pfmax"], start = 0)

    report && _IM.sol_component_value(pm, nw, :reserves, :Pgg, _PM.ids(pm, nw, :arcs_reserves_syn_ne), Pg)
    report && _IM.sol_component_value(pm, nw, :reserves, :Pff, _PM.ids(pm, nw, :arcs_reserves_syn_ne), Pf)
end


function variable_frequency_reserves_bin(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    z1 = _PM.var(pm, nw)[:z1] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z1", binary = true, start = 0 )
    z2 = _PM.var(pm, nw)[:z2] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z2", binary = true, start = 0 )
    z3 = _PM.var(pm, nw)[:z3] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z3", binary = true, start = 0 )
    z4 = _PM.var(pm, nw)[:z4] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z4", binary = true, start = 0 )
    ev_syncarea = pm.setting["syncarea"]
    zb1 = _PM.var(pm, nw)[:zb1] = JuMP.@variable(pm.model,
    [i in _PM.ref(pm, nw, :bus_arcs_conv, ev_syncarea)], base_name="$(nw)_zb1", binary = true, start = 0 )

    report && _IM.sol_component_value(pm, nw, :reserves, :z1, _PM.ids(pm, nw, :arcs_reserves_syn), z1)
    report && _IM.sol_component_value(pm, nw, :reserves, :z2, _PM.ids(pm, nw, :arcs_reserves_syn), z2)
    report && _IM.sol_component_value(pm, nw, :reserves, :z3, _PM.ids(pm, nw, :arcs_reserves_syn), z3)
    report && _IM.sol_component_value(pm, nw, :reserves, :z4, _PM.ids(pm, nw, :arcs_reserves_syn), z4)
    report && _IM.sol_component_value(pm, nw, :convdc, :zb1, _PM.ref(pm, nw, :bus_arcs_conv, ev_syncarea), zb1)

    z11 = _PM.var(pm, nw)[:z11] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z11", binary = true, start = 0 )
    z21 = _PM.var(pm, nw)[:z21] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z21", binary = true, start = 0 )
    z31 = _PM.var(pm, nw)[:z31] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z31", binary = true, start = 0 )
    z41 = _PM.var(pm, nw)[:z41] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z41", binary = true, start = 0 )
    z12 = _PM.var(pm, nw)[:z12] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z12", binary = true, start = 0 )
    z22 = _PM.var(pm, nw)[:z22] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z22", binary = true, start = 0 )
    z32 = _PM.var(pm, nw)[:z32] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z32", binary = true, start = 0 )
    z42 = _PM.var(pm, nw)[:z42] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_z42", binary = true, start = 0 )

    report && _IM.sol_component_value(pm, nw, :reserves, :z11, _PM.ids(pm, nw, :arcs_reserves_syn), z11)
    report && _IM.sol_component_value(pm, nw, :reserves, :z21, _PM.ids(pm, nw, :arcs_reserves_syn), z21)
    report && _IM.sol_component_value(pm, nw, :reserves, :z31, _PM.ids(pm, nw, :arcs_reserves_syn), z31)
    report && _IM.sol_component_value(pm, nw, :reserves, :z41, _PM.ids(pm, nw, :arcs_reserves_syn), z41)

    report && _IM.sol_component_value(pm, nw, :reserves, :z12, _PM.ids(pm, nw, :arcs_reserves_syn), z12)
    report && _IM.sol_component_value(pm, nw, :reserves, :z22, _PM.ids(pm, nw, :arcs_reserves_syn), z22)
    report && _IM.sol_component_value(pm, nw, :reserves, :z32, _PM.ids(pm, nw, :arcs_reserves_syn), z32)
    report && _IM.sol_component_value(pm, nw, :reserves, :z42, _PM.ids(pm, nw, :arcs_reserves_syn), z42)
end

function variable_frequency_reserves_bin_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    z1 = _PM.var(pm, nw)[:z1] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z1", binary = true, start = 0 )
    z2 = _PM.var(pm, nw)[:z2] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z2", binary = true, start = 0 )
    z3 = _PM.var(pm, nw)[:z3] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z3", binary = true, start = 0 )
    z4 = _PM.var(pm, nw)[:z4] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z4", binary = true, start = 0 )
    z5 = _PM.var(pm, nw)[:z5] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z5", binary = true, start = 0 )
    ev_syncarea = pm.setting["syncarea"]
    zb1 = _PM.var(pm, nw)[:zb1] = JuMP.@variable(pm.model,
    [i in _PM.ref(pm, nw, :bus_arcs_conv_ne, ev_syncarea)], base_name="$(nw)_zb1", binary = true, start = 0 )

    report && _IM.sol_component_value(pm, nw, :reserves, :z1, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z1)
    report && _IM.sol_component_value(pm, nw, :reserves, :z2, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z2)
    report && _IM.sol_component_value(pm, nw, :reserves, :z3, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z3)
    report && _IM.sol_component_value(pm, nw, :reserves, :z4, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z4)
    report && _IM.sol_component_value(pm, nw, :convdc, :zb1, _PM.ref(pm, nw, :bus_arcs_conv_ne, ev_syncarea), zb1)

    z11 = _PM.var(pm, nw)[:z11] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z11", binary = true, start = 0 )
    z21 = _PM.var(pm, nw)[:z21] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z21", binary = true, start = 0 )
    z31 = _PM.var(pm, nw)[:z31] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z31", binary = true, start = 0 )
    z41 = _PM.var(pm, nw)[:z41] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z41", binary = true, start = 0 )

    z12 = _PM.var(pm, nw)[:z12] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z12", binary = true, start = 0 )
    z22 = _PM.var(pm, nw)[:z22] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z22", binary = true, start = 0 )
    z32 = _PM.var(pm, nw)[:z32] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z32", binary = true, start = 0 )
    z42 = _PM.var(pm, nw)[:z42] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_z42", binary = true, start = 0 )

    report && _IM.sol_component_value(pm, nw, :reserves, :z11, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z11)
    report && _IM.sol_component_value(pm, nw, :reserves, :z21, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z21)
    report && _IM.sol_component_value(pm, nw, :reserves, :z31, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z31)
    report && _IM.sol_component_value(pm, nw, :reserves, :z41, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z41)

    report && _IM.sol_component_value(pm, nw, :reserves, :z12, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z12)
    report && _IM.sol_component_value(pm, nw, :reserves, :z22, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z22)
    report && _IM.sol_component_value(pm, nw, :reserves, :z32, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z32)
    report && _IM.sol_component_value(pm, nw, :reserves, :z42, _PM.ids(pm, nw, :arcs_reserves_syn_ne), z42)
end


function variable_frequency_power_dev(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)

    Phvdcoaux = _PM.var(pm, nw)[:Phvdcoaux] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_Phvdcoaux", lower_bound = 0, start = 0)

    Phvdccaux = _PM.var(pm, nw)[:Phvdccaux] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_Phvdccaux", lower_bound = 0, start = 0)

    report && _IM.sol_component_value(pm, nw, :reserves, :Phvdcoaux, _PM.ids(pm, nw, :arcs_reserves_syn), Phvdcoaux)
    report && _IM.sol_component_value(pm, nw, :reserves, :Phvdccaux, _PM.ids(pm, nw, :arcs_reserves_syn), Phvdccaux)

end

function variable_frequency_power_dev_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)

    Phvdcoaux = _PM.var(pm, nw)[:Phvdcoaux] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_Phvdcoaux", lower_bound = 0, start = 0)

    Phvdccaux = _PM.var(pm, nw)[:Phvdccaux] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_Phvdccaux", lower_bound = 0, start = 0)

    report && _IM.sol_component_value(pm, nw, :reserves, :Phvdcoaux, _PM.ids(pm, nw, :arcs_reserves_syn_ne), Phvdcoaux)
    report && _IM.sol_component_value(pm, nw, :reserves, :Phvdccaux, _PM.ids(pm, nw, :arcs_reserves_syn_ne), Phvdccaux)

end

function variable_frequency_power_dev_aux(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    k11 = _PM.var(pm, nw)[:k11] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k11", start = 0)
    k12 = _PM.var(pm, nw)[:k12] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k12", start = 0)

    k21 = _PM.var(pm, nw)[:k21] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k21", start = 0)
    k22 = _PM.var(pm, nw)[:k22] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k22", start = 0)
    k23 = _PM.var(pm, nw)[:k23] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k23", start = 0)

    k31 = _PM.var(pm, nw)[:k31] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k31", start = 0)
    k32 = _PM.var(pm, nw)[:k32] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k32", start = 0)
    k33 = _PM.var(pm, nw)[:k33] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k33", start = 0)

    k41 = _PM.var(pm, nw)[:k41] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k41", start = 0)
    k42 = _PM.var(pm, nw)[:k42] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k42", start = 0)
    k43 = _PM.var(pm, nw)[:k43] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn)], base_name="$(nw)_k43", start = 0)
end


function variable_frequency_power_dev_aux_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    k11 = _PM.var(pm, nw)[:k11] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k11", start = 0)
    k12 = _PM.var(pm, nw)[:k12] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k12", start = 0)

    k21 = _PM.var(pm, nw)[:k21] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k21", start = 0)
    k22 = _PM.var(pm, nw)[:k22] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k22", start = 0)
    k23 = _PM.var(pm, nw)[:k23] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k23", start = 0)

    k31 = _PM.var(pm, nw)[:k31] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k31", start = 0)
    k32 = _PM.var(pm, nw)[:k32] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k32", start = 0)
    k33 = _PM.var(pm, nw)[:k33] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k33", start = 0)

    k41 = _PM.var(pm, nw)[:k41] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k41", start = 0)
    k42 = _PM.var(pm, nw)[:k42] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k42", start = 0)
    k43 = _PM.var(pm, nw)[:k43] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :arcs_reserves_syn_ne)], base_name="$(nw)_k43", start = 0)
end
