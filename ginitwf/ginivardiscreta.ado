* ============================================================
* ginivardiscreta.ado
* PAQUETE: Coeficiente de Gini para Variables Discretas
* AUTOR: Washington Quintero Montaño - Universidad de Guayaquil
* EMAIL: washington.quinterom@ug.edu.ec
* VERSIÓN: 3.0
* MÉTODO: Thomas, Wang & Fan (2001)
* INSTALACIÓN: net install ginivardiscreta, from("https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/") replace
* ============================================================

* ============================================================
* PROGRAMA PRINCIPAL - ginivardiscreta
* ============================================================
program define ginivardiscreta
    version 15.0
    syntax varlist(min=1) [if] [in] , ///
        [MINobs(integer 30)]          ///
        [SHOWall]                     ///
        [REPLACE]                     ///
        [SAVE(string)]                ///
        [DETAILed]                    ///
        [PLOT]                        ///
        [VALores]                     ///
        [PROPorciones]                ///
        [NOCONFIG]
    
    * Encabezado
    display _n as text "{hline 78}"
    display as text "{bf:ginivardiscreta - COEFICIENTE DE GINI PARA VARIABLES DISCRETAS}"
    display as text "{hline 78}"
    display as text "Método: Thomas, Wang & Fan (2001) | Autor: Washington Quintero Montaño - UG"
    display as text "Mínimo de observaciones: `minobs' | Variables: `varlist'"
    if "`if'`in'" != "" display as text "Filtro: `if' `in'"
    display as text "{hline 78}"
    
    preserve
    
    * Aplicar filtros
    if "`if'`in'" != "" {
        keep `if' `in'
    }
    
    * Verificar variables de configuración
    if "`noconfig'" == "" {
        capture confirm variable _gini_value _gini_prop
        if _rc != 0 {
            display as error "{bf:ERROR:} Variables _gini_value o _gini_prop no encontradas."
            display as error "Use {bf:ginisetup} para configurar su variable:"
            display as error "  ginisetup, variable(mi_variable)"
            display as error "O use la opción {bf:noconfig} si ya tiene variables numéricas."
            restore
            exit 111
        }
    }
    
    * Procesar cada variable de agrupación
    foreach var of local varlist {
        display _n as text "{bf:ANÁLISIS POR:} `var'"
        display as text "{hline 60}"
        
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
                
                * Calcular Gini para este grupo
                gini_calcular "`var'" `nivel' "`etiqueta'" `n_obs' "`valores'" "`proporciones'"
            }
            else if "`showall'" != "" {
                display as text "  `etiqueta': " as result "Insuficientes observaciones (N=`n_obs')"
            }
        }
        
        display as text "{hline 60}"
        display as text "Resumen: " as result "`grupos_validos'" as text " de " ///
            as result "`total_grupos'" as text " grupos válidos"
    }
    
    restore
    
    display _n as text "{hline 78}"
    display as text "{bf:ANÁLISIS COMPLETADO}"
    display as text "Paquete ginivardiscreta v3.0 - Washington Quintero Montaño - UG"
    display as text "{hline 78}"
end

* ============================================================
* PROGRAMA: ginisetup - CONFIGURACIÓN GENÉRICA
* ============================================================
program define ginisetup
    version 15.0
    syntax, VARiable(string) [AUTOmatic]
    
    display _n
    display as text "{hline 60}"
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN GENÉRICA}"
    display as text "{hline 60}"
    display as text "Variable a configurar: `variable'"
    display as text "{hline 60}"
    
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
    display _n as text "Ahora puede usar: {bf:ginivardiscreta} variable_grupo"
    display as text "{hline 60}"
end

* ============================================================
* PROGRAMA: ginieducacion - CONFIGURACIÓN ESPECÍFICA PARA EDUCACIÓN
* ============================================================
program define ginieducacion
    version 15.0
    syntax, VARiable(string)
    
    display _n
    display as text "{hline 60}"
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN PARA VARIABLES EDUCATIVAS}"
    display as text "{hline 60}"
    display as text "Método: Thomas, Wang & Fan (2001)"
    display as text "Variable educativa: `variable'"
    display as text "{hline 60}"
    
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
    
    * Crear etiquetas para niveles educativos
    label define gini_nivel 0 "Sin nivel" 2.72 "Primaria incompleta" ///
        6 "Primaria completa" 8.48 "Secundaria incompleta" ///
        11 "Secundaria completa" 13.54 "Superior incompleta" ///
        16.07 "Superior completa" 18 "Posgrado"
    label values _gini_value gini_nivel
    
    display as text "✓ Valores educativos asignados"
    display as text "✓ Proporciones calculadas"
    display as text "✓ Configuración educativa completada"
    
    * Mostrar distribución
    display _n as text "{bf:DISTRIBUCIÓN POR NIVELES EDUCATIVOS:}"
    tabulate _gini_value, summarize(_gini_prop)
    
    display _n as text "Ahora puede usar: {bf:ginivardiscreta} variable_grupo"
    display as text "{hline 60}"
end

* ============================================================
* SUBPROGRAMA: CÁLCULO DEL COEFICIENTE DE GINI
* ============================================================
program define gini_calcular
    args var_grupo nivel etiqueta n_obs valores proporciones
    
    quietly {
        preserve
        
        * Mantener solo el grupo actual
        keep if `var_grupo' == `nivel' & !missing(_gini_value, _gini_prop)
        
        * Obtener valores únicos y sus proporciones
        quietly tabulate _gini_value, matrow(valores_unicos)
        local n_valores = r(r)
        
        matrix proporciones_mat = J(`n_valores', 1, .)
        forvalues i = 1/`n_valores' {
            local valor = valores_unicos[`i', 1]
            count if _gini_value == `valor'
            matrix proporciones_mat[`i', 1] = r(N) / _N
        }
        
        * Calcular valor promedio ponderado
        local mu = 0
        forvalues i = 1/`n_valores' {
            local valor = valores_unicos[`i', 1]
            local prop = proporciones_mat[`i', 1]
            local mu = `mu' + `valor' * `prop'
        }
        
        * Calcular sumatoria doble para Gini (Thomas et al. 2001)
        local sumatoria = 0
        forvalues i = 1/`n_valores' {
            forvalues j = 1/`=`i'-1' {
                local valor_i = valores_unicos[`i', 1]
                local valor_j = valores_unicos[`j', 1]
                local prop_i = proporciones_mat[`i', 1]
                local prop_j = proporciones_mat[`j', 1]
                local diff = abs(`valor_i' - `valor_j')
                local producto = `prop_i' * `diff' * `prop_j'
                local sumatoria = `sumatoria' + `producto'
            }
        }
        
        * Coeficiente de Gini
        local gini = `sumatoria' / `mu'
        
        * Clasificar nivel de desigualdad
        if `gini' < 0.2 local des "BAJA"
        else if `gini' < 0.35 local des "MEDIA" 
        else if `gini' < 0.5 local des "ALTA"
        else local des "MUY ALTA"
        
        * Mostrar distribución si se solicita
        if "`valores'" != "" | "`proporciones'" != "" {
            display as text "    Distribución de valores:"
            forvalues i = 1/`n_valores' {
                local valor = valores_unicos[`i', 1]
                local porcentaje = proporciones_mat[`i', 1] * 100
                local etiqueta_valor : label (_gini_value) `valor'
                display as text "      `etiqueta_valor': " as result %5.1f `porcentaje' "%"
            }
        }
        
        restore
    }
    
    * Mostrar resultado formateado
    display as text "  `etiqueta' " _col(25) "| " ///
        as result "Gini: " %6.4f `gini' " (" "`des'" ")" _col(55) "| " ///
        as result "Promedio: " %5.2f `mu' _col(70) "| " ///
        as result "N: `n_obs'"
end

* ============================================================
* PROGRAMA: giniresumen - RESUMEN EJECUTIVO
* ============================================================
program define giniresumen
    version 15.0
    syntax [varlist] [if] [in], [MINobs(integer 30)]
    
    display _n
    display as text "{hline 60}"
    display as text "{bf:ginivardiscreta - RESUMEN EJECUTIVO}"
    display as text "{hline 60}"
    display as text "Análisis rápido de desigualdad"
    display as text "{hline 60}"
    
    if "`varlist'" == "" {
        local varlist "region provincia area"
        display as text "Variables por defecto: region provincia area"
    }
    
    ginivardiscreta `varlist' `if' `in', minobs(`minobs')
end

* ============================================================
* PROGRAMA: ginihelp - AYUDA RÁPIDA
* ============================================================
program define ginihelp
    display _n
    display as text "{bf:ginivardiscreta - AYUDA RÁPIDA}"
    display as text "{hline 60}"
    display as text "Comandos disponibles:"
    display as text "  {bf:ginisetup}      - Configuración genérica"
    display as text "  {bf:ginieducacion}  - Configuración para educación"
    display as text "  {bf:ginivardiscreta}- Análisis principal"
    display as text "  {bf:giniresumen}    - Resumen ejecutivo"
    display as text "  {bf:ginihelp}       - Esta ayuda"
    display _n
    display as text "Ejemplos de uso:"
    display as text "  ginisetup, variable(ingreso)"
    display as text "  ginieducacion, variable(anios_educ)"
    display as text "  ginivardiscreta provincia, minobs(50)"
    display as text "  giniresumen"
    display as text "{hline 60}"
end

* ============================================================
* INICIALIZACIÓN - Mostrar mensaje al cargar
* ============================================================
display as text "Paquete {bf:ginivardiscreta} v3.0 cargado correctamente"
display as text "Autor: Washington Quintero Montaño - Universidad de Guayaquil"
display as text "Use {bf:ginihelp} para ver los comandos disponibles"

* ============================================================
* FIN DEL ARCHIVO ginivardiscreta.ado
* ============================================================
