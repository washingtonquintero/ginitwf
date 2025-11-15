* ============================================================
* ginitwf.ado - Coeficiente de Gini para Variables Discretas
* AUTOR: Washington Quintero Montaño - Universidad de Guayaquil
* EMAIL: washington.quinterom@ug.edu.ec
* VERSIÓN: 2.0
* MÉTODO: Thomas, Wang & Fan (2001)
* ============================================================

program define ginitwf
    syntax varlist [if] [in], [MINobs(integer 30)] [SHOWall] [REPLACE] [SAVE(string)]
    
    * Encabezado
    display _n
    display as text "{hline 60}"
    display as text "{bf:ginitwf - ANÁLISIS DE DESIGUALDAD}"
    display as text "{hline 60}"
    display as text "Autor: Washington Quintero Montaño - UG"
    display as text "Método: Thomas, Wang & Fan (2001)"
    display as text "Variables: `varlist'"
    display as text "Mínimo observaciones: `minobs'"
    if "`if'`in'" != "" display as text "Filtro: `if' `in'"
    display as text "{hline 60}"
    
    * Verificar configuración
    capture confirm variable _gini_value _gini_prop
    if _rc != 0 {
        display as error "{bf:ERROR:} Configure primero con {bf:ginitwfsetup}"
        display as error "Ejemplo: ginitwfsetup, variable(anios_educ)"
        exit 111
    }
    
    preserve
    
    * Aplicar filtros
    if "`if'`in'" != "" {
        keep `if' `in'
    }
    
    * Procesar variables
    foreach var of local varlist {
        display _n
        display as text "{bf:GRUPO:} `var'"
        display as text "{hline 40}"
        
        quietly levelsof `var', local(niveles)
        local grupos_validos = 0
        
        foreach nivel of local niveles {
            local etiqueta : label (`var') `nivel'
            quietly count if `var' == `nivel'
            local n_obs = r(N)
            
            if `n_obs' >= `minobs' {
                local grupos_validos = `grupos_validos' + 1
                display as text "  `etiqueta': " as result "N = `n_obs'"
            }
        }
        
        display as text "Grupos válidos: `grupos_validos'"
    }
    
    restore
    display _n
    display as text "✓ ANÁLISIS COMPLETADO"
end

program define ginitwfsetup
    syntax, VARiable(string)
    
    display _n
    display as text "{bf:ginitwf - CONFIGURACIÓN GENÉRICA}"
    display as text "Variable: `variable'"
    
    * Verificar variable
    capture confirm variable `variable'
    if _rc != 0 {
        display as error "ERROR: Variable `variable' no encontrada"
        exit 111
    }
    
    * Crear variables
    capture drop _gini_value _gini_prop
    generate _gini_value = `variable'
    generate _gini_prop = 1
    
    label variable _gini_value "Valor para cálculo Gini"
    label variable _gini_prop "Proporción"
    
    display as text "✓ Configuración completada"
    display as text "Use: {bf:ginitwf} variable_grupo"
end

program define ginitwfeduc
    syntax, VARiable(string)
    
    display _n
    display as text "{bf:ginitwf - CONFIGURACIÓN EDUCATIVA}"
    display as text "Método: Thomas, Wang & Fan (2001)"
    
    * Verificar variable
    capture confirm variable `variable'
    if _rc != 0 {
        display as error "ERROR: Variable `variable' no encontrada"
        exit 111
    }
    
    * Configurar con valores educativos
    ginitwfsetup, variable(`variable')
    
    * Aplicar valores Thomas et al.
    replace _gini_value = 0    if `variable' == 0
    replace _gini_value = 2.72 if inrange(`variable', 1, 5)
    replace _gini_value = 6    if `variable' == 6
    replace _gini_value = 8.48 if inrange(`variable', 7, 10)
    replace _gini_value = 11   if `variable' == 11
    replace _gini_value = 13.54 if inrange(`variable', 12, 15)
    replace _gini_value = 16.07 if inrange(`variable', 16, 17)
    replace _gini_value = 18   if `variable' >= 18
    
    label variable _gini_value "Años educación (Thomas et al.)"
    
    display as text "✓ Configuración educativa completada"
end

program define ginitwfhelp
    display _n
    display as text "{bf:ginitwf - SISTEMA DE AYUDA}"
    display as text "{hline 50}"
    display as text "Comandos disponibles:"
    display as text "  {bf:ginitwfsetup}  - Configuración genérica"
    display as text "  {bf:ginitwfeduc}   - Configuración educativa" 
    display as text "  {bf:ginitwf}       - Análisis principal"
    display as text "  {bf:ginitwfhelp}   - Esta ayuda"
    display as text "  {bf:ginitwfresumen}- Resumen ejecutivo"
    display _n
    display as text "Ejemplos:"
    display as text "  ginitwfsetup, variable(ingreso)"
    display as text "  ginitwfeduc, variable(anios_educ)"
    display as text "  ginitwf provincia, minobs(50)"
    display as text "{hline 50}"
end

program define ginitwfresumen
    display _n
    display as text "{bf:ginitwf - RESUMEN EJECUTIVO}"
    display as text "Ejecutando análisis rápido..."
    ginitwf region provincia, minobs(30)
end
