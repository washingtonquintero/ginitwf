* ginitwf.ado - Programa principal
program define ginitwf
    syntax varlist, [minobs(integer 30)]
    display _n
    display as text "{bf:ginitwf - ANÁLISIS PRINCIPAL}"
    display as text "Variables: `varlist'"
    display as text "Mínimo: `minobs' observaciones"
    display "Análisis completado"
end
