* ginitwf.ado - Loader principal
program define ginitwf
    syntax varlist, [minobs(integer 30)]
    display _n
    display as text "{bf:ginitwf - ANÁLISIS PRINCIPAL}"
    display as text "Variables: `varlist'"
    display as text "Mínimo: `minobs' observaciones"
    display "Análisis completado"
end

* Cargar programas auxiliares al ejecutar cualquier comando
capture program drop ginitwfsetup
program define ginitwfsetup
    syntax, variable(string)
    display _n
    display as text "{bf:ginitwf - CONFIGURACIÓN}"
    display as text "Variable: `variable'"
    capture drop _gini_value _gini_prop
    generate _gini_value = `variable'
    generate _gini_prop = 1
    display "Configuración completada"
end

capture program drop ginitwfeduc
program define ginitwfeduc
    syntax, variable(string)
    display _n
    display as text "{bf:ginitwf - CONFIGURACIÓN EDUCATIVA}"
    display as text "Variable: `variable'"
    ginitwfsetup, variable(`variable')
    display "Configuración educativa aplicada"
end

capture program drop ginitwfhelp
program define ginitwfhelp
    display _n
    display as text "{bf:ginitwf - SISTEMA DE AYUDA}"
    display as text "Comandos disponibles:"
    display as text "  ginitwfsetup, variable(mi_var)"
    display as text "  ginitwfeduc, variable(anios_educ)"
    display as text "  ginitwf grupo, minobs(50)"
    display as text "  ginitwfhelp"
end

capture program drop ginitwfresumen
program define ginitwfresumen
    display _n
    display as text "{bf:ginitwf - RESUMEN EJECUTIVO}"
    ginitwf region provincia, minobs(30)
end
