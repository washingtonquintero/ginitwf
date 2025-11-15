* ginitwf-help.ado - Sistema de ayuda
program define ginitwfhelp
    display _n
    display as text "{bf:ginitwf - SISTEMA DE AYUDA}"
    display as text "Comandos disponibles:"
    display as text "  ginitwfsetup, variable(mi_var)"
    display as text "  ginitwfeduc, variable(anios_educ)"
    display as text "  ginitwf grupo, minobs(50)"
    display as text "  ginitwfhelp"
    display as text "  ginitwfresumen"
end
