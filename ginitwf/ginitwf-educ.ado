* ginitwf-educ.ado - Configuración educativa
program define ginitwfeduc
    syntax, variable(string)
    display _n
    display as text "{bf:ginitwf - CONFIGURACIÓN EDUCATIVA}"
    display as text "Variable: `variable'"
    ginitwfsetup, variable(`variable')
    display "Configuración educativa aplicada"
end
