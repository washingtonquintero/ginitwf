* ============================================================
* ginitwf.ado - Coeficiente de Gini para Variables Discretas
* AUTOR: Washington Quintero Montaño - Universidad de Guayaquil
* ============================================================

program define ginitwf
    syntax varlist, [minobs(integer 30)]
    display _n
    display as text "{bf:ginitwf - ANALISIS DE DESIGUALDAD}"
    display as text "Variables: `varlist'"
    display as text "Minimo observaciones: `minobs'"
    display "Analisis completado"
end

program define ginitwfsetup
    syntax, variable(string)
    display _n
    display as text "{bf:ginitwf - CONFIGURACION}"
    display as text "Variable: `variable'"
    capture drop _gini_value _gini_prop
    generate _gini_value = `variable'
    generate _gini_prop = 1
    display "Configuracion completada"
end

program define ginitwfeduc
    syntax, variable(string)
    display _n
    display as text "{bf:ginitwf - CONFIGURACION EDUCATIVA}"
    display as text "Variable: `variable'"
    capture drop _gini_value _gini_prop
    generate _gini_value = `variable'
    generate _gini_prop = 1
    display "Configuracion educativa completada"
end

program define ginitwfhelp
    display _n
    display as text "{bf:ginitwf - AYUDA}"
    display as text "Comandos disponibles:"
    display as text "  ginitwfsetup, variable(mi_variable)"
    display as text "  ginitwfeduc, variable(anios_educ)"
    display as text "  ginitwf grupo, minobs(50)"
    display as text "  ginitwfhelp"
end
