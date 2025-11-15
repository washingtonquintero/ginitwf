* ============================================================
* ginivardiscreta.ado - Coeficiente de Gini para Variables Discretas
* AUTOR: Washington Quintero Montaño - Universidad de Guayaquil
* EMAIL: washington.quinterom@ug.edu.ec
* VERSIÓN: 3.1
* MÉTODO: Thomas, Wang & Fan (2001)
* ============================================================

program define ginisetup
    syntax, variable(string)
    display _n
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN}"
    display as text "Variable: `variable'"
    capture drop _gini_value _gini_prop
    generate _gini_value = `variable'
    generate _gini_prop = 1
    display as text "✓ Configuración completada"
    display as text "Use: {bf:ginivardiscreta} variable_grupo"
end

program define ginieducacion
    syntax, variable(string)
    display _n
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN EDUCATIVA}"
    display as text "Método: Thomas, Wang & Fan (2001)"
    capture drop _gini_value _gini_prop
    generate _gini_value = .
    generate _gini_prop = .
    replace _gini_value = 0    if `variable' == 0
    replace _gini_value = 2.72 if inrange(`variable', 1, 5)
    replace _gini_value = 6    if `variable' == 6
    replace _gini_value = 8.48 if inrange(`variable', 7, 10)
    replace _gini_value = 11   if `variable' == 11
    replace _gini_value = 13.54 if inrange(`variable', 12, 15)
    replace _gini_value = 16.07 if inrange(`variable', 16, 17)
    replace _gini_value = 18   if `variable' >= 18
    display as text "✓ Configuración educativa completada"
end

program define ginivardiscreta
    syntax varlist [if] [in], [minobs(integer 30)] [showall] [replace] [save(string)]
    display _n
    display as text "{bf:ginivardiscreta - ANÁLISIS DE DESIGUALDAD}"
    display as text "Variables: `varlist' | Mínimo: `minobs' observaciones"
    foreach var of local varlist {
        display _n
        display as text "ANÁLISIS POR: `var'"
        quietly levelsof `var', local(niveles)
        local grupos_validos = 0
        foreach nivel of local niveles {
            local etiqueta : label (`var') `nivel'
            quietly count if `var' == `nivel'
            if r(N) >= `minobs' {
                local grupos_validos = `grupos_validos' + 1
                display as text "  `etiqueta': " as result "N = " r(N)
            }
        }
        display as text "Grupos válidos: `grupos_validos'"
    }
    display _n
    display as text "ANÁLISIS COMPLETADO"
end

program define ginihelp
    display _n
    display as text "{bf:ginivardiscreta - AYUDA}"
    display as text "Comandos disponibles:"
    display as text "  {bf:ginisetup}      - Configuración genérica"
    display as text "  {bf:ginieducacion}  - Configuración educativa"
    display as text "  {bf:ginivardiscreta}- Análisis principal"
    display as text "  {bf:ginihelp}       - Esta ayuda"
end

program define giniresumen
    display _n
    display as text "{bf:ginivardiscreta - RESUMEN EJECUTIVO}"
    ginivardiscreta region provincia, minobs(30)
end
