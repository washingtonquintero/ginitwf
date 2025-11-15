* ginitwf.ado - Washington Quintero Montaño - UG
program define ginitwf
    syntax varlist, [minobs(integer 30)]
    display "ginitwf: Analizando `varlist' con minobs(`minobs')"
end

program define ginitwfsetup
    syntax, variable(string)
    display "ginitwfsetup: Configurando `variable'"
end

program define ginitwfeduc
    syntax, variable(string)
    display "ginitwfeduc: Configuracion educativa `variable'"
end

program define ginitwfhelp
    display "ginitwfhelp: Comandos disponibles"
end

program define ginitwfresumen
    display "ginitwfresumen: Resumen ejecutivo"
end
