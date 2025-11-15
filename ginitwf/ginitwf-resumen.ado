* ginitwf-resumen.ado - Resumen ejecutivo
program define ginitwfresumen
    display _n
    display as text "{bf:ginitwf - RESUMEN EJECUTIVO}"
    ginitwf region provincia, minobs(30)
end
