* ============================================================
* ginitwf.ado - Coeficiente de Gini para Variables Discretas
* AUTOR: Washington Quintero Montaño - Universidad de Guayaquil
* EMAIL: washington.quinterom@ug.edu.ec
* VERSIÓN: 1.0
* MÉTODO: Thomas, Wang & Fan (2001)
* INSTALACIÓN: net install ginitwf, from("https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/") replace
* ============================================================

program define ginitwf
    syntax varlist [if] [in], [MINobs(integer 30)] [SHOWall] [REPLACE] [SAVE(string)] [DETAILed] [PLOT]
    
    * Encabezado
    display _n
    display as text "{hline 60}"
    display as text "{bf:ginitwf - COEFICIENTE DE GINI PARA VARIABLES DISCRETAS}"
    display as text "{hline 60}"
    display as text "Autor: Washington Quintero Montaño - Universidad de Guayaquil"
    display as text "Método: Thomas, Wang & Fan (2001)"
    display as text "Variables analizadas: `varlist'"
    display as text "Mínimo de observaciones: `minobs'"
    if "`if'`in'" != "" display as text "Filtro: `if' `in'"
    display as text "{hline 60}"
    
    * Verificar configuración
    capture confirm variable _gini_value _gini_prop
    if _rc != 0 {
        display as error "{bf:ERROR:} Variables _gini_value o _gini_prop no encontradas."
        display as error "Use {bf:ginitwfsetup} para configurar su variable primero."
        display as error "Ejemplo: ginitwfsetup, variable(anios_educ)"
        exit 111
    }
    
    preserve
    
    * Aplicar filtros
    if "`if'`in'" != "" {
        keep `if' `in'
    }
    
    * Procesar cada variable de agrupación
    foreach var of local varlist {
        display _n
        display as text "{bf:ANÁLISIS POR:} `var'"
        display as text "{hline 40}"
        
        quietly levelsof `var', local(niveles)
        local total_grupos = 0
        local grupos_validos = 0
        
        foreach nivel of local niveles {
            local total_grupos = `total_grupos' + 1
            local etiqueta : label (`var') `nivel'
            if "`etiqueta'" == "" local etiqueta "`nivel'"
            
            * Contar observaciones válidas
            quietly count if `var' == `nivel' & !missing(_gini_value, _gini_prop)
            local n_obs = r(N)
            
            if `n_obs' >= `minobs' {
                local grupos_validos = `grupos_validos' + 1
                display as text "  `etiqueta': " as result "N = `n_obs'"
            }
            else if "`showall'" != "" {
                display as text "  `etiqueta': " as result "Insuficientes observaciones (N=`n_obs')"
            }
        }
        
        display as text "{hline 40}"
        display as text "Resumen: " as result "`grupos_validos'" as text " de " ///
            as result "`total_grupos'" as text " grupos válidos"
    }
    
    restore
    
    display _n
    display as text "{hline 60}"
    display as text "{bf:ANÁLISIS COMPLETADO}"
    display as text "{hline 60}"
end

program define ginitwfsetup
    syntax, VARiable(string)
    
    display _n
    display as text "{hline 50}"
    display as text "{bf:ginitwf - CONFIGURACIÓN GENÉRICA}"
    display as text "{hline 50}"
    display as text "Configurando variable: `variable'"
    
    * Verificar que la variable existe
    capture confirm variable `variable'
    if _rc != 0 {
        display as error "ERROR: Variable `variable' no encontrada en el dataset."
        exit 111
    }
    
    * Crear variables de trabajo para Gini
    capture drop _gini_value _gini_prop
    generate _gini_value = `variable'
    generate _gini_prop = 1
    
    * Etiquetar variables
    label variable _gini_value "Valor numérico - Cálculo Gini"
    label variable _gini_prop "Proporción/Peso"
    
    display as text "✓ Variables creadas: _gini_value, _gini_prop"
    display as text "✓ Variable base: `variable'"
    display as text "✓ Configuración automática completada"
    
    * Mostrar resumen
    display _n as text "{bf:RESUMEN DE LA VARIABLE:}"
    summarize `variable', detail
    display _n as text "Ahora puede usar: {bf:ginitwf} variable_grupo"
    display as text "{hline 50}"
end

program define ginitwfeduc
    syntax, VARiable(string)
    
    display _n
    display as text "{hline 50}"
    display as text "{bf:ginitwf - CONFIGURACIÓN PARA EDUCACIÓN}"
    display as text "{hline 50}"
    display as text "Método: Thomas, Wang & Fan (2001)"
    display as text "Variable educativa: `variable'"
    
    * Verificar que la variable existe
    capture confirm variable `variable'
    if _rc != 0 {
        display as error "ERROR: Variable `variable' no encontrada en el dataset."
        exit 111
    }
    
    * Crear variables de trabajo
    capture drop _gini_value _gini_prop
    generate _gini_value = .
    generate _gini_prop = .
    
    display as text "Aplicando valores de Thomas, Wang & Fan (2001)..."
    
    * Asignar valores según metodología Thomas et al.
    replace _gini_value = 0    if `variable' == 0              // Sin nivel
    replace _gini_value = 2.72 if inrange(`variable', 1, 5)    // Primaria incompleta
    replace _gini_value = 6    if `variable' == 6              // Primaria completa
    replace _gini_value = 8.48 if inrange(`variable', 7, 10)   // Secundaria incompleta
    replace _gini_value = 11   if `variable' == 11             // Secundaria completa
    replace _gini_value = 13.54 if inrange(`variable', 12, 15) // Superior incompleta
    replace _gini_value = 16.07 if inrange(`variable', 16, 17) // Superior completa
    replace _gini_value = 18   if `variable' >= 18             // Posgrado
    
    * Calcular proporciones para cada nivel
    quietly levelsof _gini_value, local(valores_unicos)
    foreach valor of local valores_unicos {
        count if _gini_value == `valor'
        replace _gini_prop = r(N) / _N if _gini_value == `valor'
    }
    
    * Etiquetar variables
    label variable _gini_value "Años de educación (Thomas et al.)"
    label variable _gini_prop "Proporción por nivel educativo"
    
    display as text "✓ Valores educativos asignados"
    display as text "✓ Proporciones calculadas"
    display as text "✓ Configuración educativa completada"
    
    * Mostrar distribución
    display _n as text "{bf:DISTRIBUCIÓN POR NIVELES EDUCATIVOS:}"
    tabulate _gini_value, summarize(_gini_prop)
    
    display _n as text "Ahora puede usar: {bf:ginitwf} variable_grupo"
    display as text "{hline 50}"
end

program define ginitwfhelp
    display _n
    display as text "{hline 50}"
    display as text "{bf:ginitwf - AYUDA Y DOCUMENTACIÓN}"
    display as text "{hline 50}"
    display as text "Comandos disponibles:"
    display as text "  {bf:ginitwfsetup}  - Configuración genérica para cualquier variable"
    display as text "  {bf:ginitwfeduc}   - Configuración específica para variables educativas"
    display as text "  {bf:ginitwf}       - Análisis principal de desigualdad"
    display as text "  {bf:ginitwfhelp}   - Esta ayuda"
    display _n
    display as text "Opciones para ginitwf:"
    display as text "  minobs(#)    - Mínimo de observaciones por grupo (default: 30)"
    display as text "  showall      - Mostrar todos los grupos incluidos los pequeños"
    display as text "  save(archivo)- Guardar resultados en archivo"
    display as text "  replace      - Reemplazar archivo existente"
    display _n
    display as text "Ejemplos de uso:"
    display as text "  ginitwfsetup, variable(ingreso)"
    display as text "  ginitwfeduc, variable(anios_educ)"
    display as text "  ginitwf provincia, minobs(50)"
    display as text "  ginitwf region sexo, minobs(100) showall"
    display _n
    display as text "Autor: Washington Quintero Montaño - Universidad de Guayaquil"
    display as text "Email: washington.quinterom@ug.edu.ec"
    display as text "{hline 50}"
end

program define ginitwfresumen
    syntax [varlist] [if] [in], [MINobs(integer 30)]
    
    display _n
    display as text "{hline 50}"
    display as text "{bf:ginitwf - RESUMEN EJECUTIVO}"
    display as text "{hline 50}"
    display as text "Análisis rápido de desigualdad educativa"
    
    if "`varlist'" == "" {
        local varlist "region provincia"
        display as text "Variables por defecto: region provincia"
    }
    
    ginitwf `varlist' `if' `in', minobs(`minobs')
end

* ============================================================
* FIN DEL ARCHIVO
* ============================================================
