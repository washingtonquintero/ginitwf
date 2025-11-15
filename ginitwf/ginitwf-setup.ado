* ginitwf-setup.ado - Configuración genérica
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
