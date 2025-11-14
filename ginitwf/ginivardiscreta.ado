* ============================================================
* PROGRAMA: ginivardiscreta.ado
* PAQUETE: ginivardiscreta - Gini para Variables Discretas Genéricas
* VERSIÓN: 2.0
* AUTOR: Washington Quintero Montaño
* INSTITUCIÓN: Universidad de Guayaquil
* EMAIL: washington.quinterom@ug.edu.ec
* REPOSITORIO: github.com/washingtonquintero/ginitwf
* INSTALACIÓN: net install ginivardiscreta, from("https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/") replace
* MÉTODO: Thomas, Wang & Fan (2001) para variables discretas
* ============================================================

program define ginivardiscreta
    version 14.0
    syntax varlist(min=1) [if] [in] , ///
        [MINobs(integer 30)]          ///
        [SHOWall]                     ///
        [REPLACE]                     ///
        [SAVE(string)]                ///
        [DETAILed]                    ///
        [PLOT]                        ///
        [VALores(string)]             ///
        [PROPorciones(string)]        ///
        [NOCONFIG]
    
    * Display header
    display _n
    display as text "{hline 78}"
    display as text "{bf:ginivardiscreta - GINI PARA VARIABLES DISCRETAS GENÉRICAS}"
    display as text "{hline 78}"
    display as text "Metodología: {bf:Thomas, Wang & Fan (2001)} para variables discretas"
    display as text "Autor:       Washington Quintero Montaño - Universidad de Guayaquil"
    display as text "Repositorio: github.com/washingtonquintero/ginitwf"
    display as text "Mínimo de observaciones: `minobs'"
    display as text "Variables analizadas: `varlist'"
    if "`if'`in'" != "" display as text "Filtro aplicado: `if' `in'"
    display as text "{hline 78}"
    
    preserve
    
    * Aplicar filtros si existen
    if "`if'`in'" != "" {
        keep `if' `in'
    }
    
    * Verificar configuración automática
    if "`noconfig'" == "" {
        capture confirm variable _gini_value _gini_prop
        if _rc != 0 {
            display as error "{bf:ADVERTENCIA:} Variables _gini_value o _gini_prop no encontradas."
            display as error "Use {bf:giniconfig} para configurar su variable discreta, o"
            display as error "use la opción {bf:noconfig} si ya tiene variables numéricas."
            restore
            exit 111
        }
    }
    
    * Crear matriz para almacenar resultados si se solicita guardar
    if "`save'" != "" | "`replace'" != "" {
        tempname resultados
        mata: `resultados' = J(0, 6, .)
    }
    
    * Procesar cada variable de agrupación
    foreach var of local varlist {
        display _n
        display as text "{bf:ANÁLISIS POR:} `var'"
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
                ginicalcular "`var'" `nivel' "`etiqueta'" `n_obs' "`resultados'" "`save'" "`valores'" "`proporciones'"
            }
            else if "`showall'" != "" {
                display as text "  `etiqueta': " as result "Insuficientes observaciones (N=`n_obs')"
            }
        }
        
        display as text "{hline 60}"
        display as text "Resumen: " as result "`grupos_validos'" as text " de " ///
            as result "`total_grupos'" as text " grupos válidos"
    }
    
    * Guardar resultados si se solicita
    if "`save'" != "" {
        giniguardar "`resultados'" "`save'" "`replace'"
    }
    
    * Mostrar gráfico si se solicita
    if "`plot'" != "" {
        giniplot "`varlist'"
    }
    
    restore
    
    display _n
    display as text "{hline 78}"
    display as text "{bf:CÁLCULO COMPLETADO - ginivardiscreta}"
    display as text "Washington Quintero Montaño - Universidad de Guayaquil"
    display as text "github.com/washingtonquintero/ginitwf"
    display as text "{hline 78}"
end

* ============================================================
* SUBPROGRAMA: CÁLCULO DEL GINI GENÉRICO
* ============================================================
program define ginicalcular
    args var_grupo nivel etiqueta n_obs resultados save valores proporciones
    
    quietly {
        preserve
        
        * Mantener solo el grupo actual
        keep if `var_grupo' == `nivel' & !missing(_gini_value, _gini_prop)
        
        * Obtener valores y proporciones únicos
        quietly tabulate _gini_value, matrow(valores_unicos)
        local n_valores = r(r)
        
        * Calcular proporciones para cada valor
        matrix proporciones_mat = J(`n_valores', 1, .)
        forvalues i = 1/`n_valores' {
            local valor = valores_unicos[`i', 1]
            count if _gini_value == `valor'
            matrix proporciones_mat[`i', 1] = r(N) / _N
        }
        
        * Calcular valor promedio
        local mu = 0
        forvalues i = 1/`n_valores' {
            local valor = valores_unicos[`i', 1]
            local prop = proporciones_mat[`i', 1]
            local mu = `mu' + `valor' * `prop'
        }
        
        * Calcular sumatoria doble para Gini (ecuación Thomas et al.)
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
        
        * Mostrar detalles si se solicita
        if "`valores'" != "" | "`proporciones'" != "" {
            display as text "    Distribución de valores:"
            forvalues i = 1/`n_valores' {
                local valor = valores_unicos[`i', 1]
                local porcentaje = proporciones_mat[`i', 1] * 100
                display as text "      Valor `valor': " as result %5.1f `porcentaje' "%"
            }
        }
        
        * Almacenar en mata si se solicita guardar
        if "`save'" != "" {
            mata: `resultados' = `resultados' \ ///
                (`nivel', `gini', `mu', `n_obs', "`var_grupo'", "`etiqueta'")
        }
        
        restore
    }
    
    * Mostrar resultados formateados
    display as text "  `etiqueta' " _col(25) "| " ///
        as result "Gini: " %6.4f `gini' " (" "`des'" ")" _col(55) "| " ///
        as result "Promedio: " %5.2f `mu' _col(70) "| " ///
        as result "N: `n_obs'"
end

* ============================================================
* PROGRAMA AUXILIAR: CONFIGURACIÓN GENÉRICA
* ============================================================
program define giniconfig
    syntax, VARiable(string) [VALores(numlist)] [PROPorciones(numlist)] [AUTOmatic]
    
    display _n
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN GENÉRICA}"
    display as text "{hline 60}"
    display as text "Configuración para variables discretas genéricas"
    display as text "Autor: Washington Quintero Montaño - Universidad de Guayaquil"
    display as text "{hline 60}"
    
    * Verificar que la variable existe
    capture confirm variable `variable'
    if _rc != 0 {
        display as error "Variable `variable' no encontrada en el dataset"
        exit 111
    }
    
    * Configuración automática
    if "`automatic'" != "" {
        display as text "Configuración automática para: `variable'"
        
        * Crear variables de trabajo
        capture drop _gini_value _gini_prop
        generate _gini_value = `variable'
        generate _gini_prop = 1
        
        * Etiquetar variables
        label variable _gini_value "Valor numérico para cálculo Gini"
        label variable _gini_prop "Proporción (1 para casos individuales)"
        
        display as text "✓ Configuración automática completada"
        display as text "✓ Variable: `variable'"
        display as text "✓ Valores únicos detectados automáticamente"
    }
    else if "`valores'" != "" & "`proporciones'" != "" {
        * Configuración manual con valores y proporciones
        local n_valores : word count `valores'
        local n_prop : word count `proporciones'
        
        if `n_valores' != `n_prop' {
            display as error "Error: Número de valores y proporciones no coincide"
            exit 198
        }
        
        display as text "Configuración manual con valores y proporciones"
        
        * Crear variables de trabajo
        capture drop _gini_value _gini_prop
        clear
        set obs `n_valores'
        
        * Asignar valores y proporciones
        local i = 1
        foreach valor of local valores {
            replace _gini_value = `valor' in `i'
            local i = `i' + 1
        }
        
        local i = 1
        foreach prop of local proporciones {
            replace _gini_prop = `prop' in `i'
            local i = `i' + 1
        }
        
        display as text "✓ Configuración manual completada"
        display as text "✓ Valores: `valores'"
        display as text "✓ Proporciones: `proporciones'"
    }
    else {
        display as error "Especifique {bf:automatic} o {bf:valores()} y {bf:proporciones()}"
        exit 198
    }
    
    * Mostrar resumen
    display _n
    display as text "{bf:RESUMEN DE CONFIGURACIÓN:}"
    tabulate _gini_value, summarize(_gini_prop)
    summarize _gini_value _gini_prop, detail
end

* ============================================================
* PROGRAMA AUXILIAR: CONFIGURACIÓN PARA EDUCACIÓN (backward compatibility)
* ============================================================
program define ginieducacion
    syntax, VARiable(string)
    
    display _n
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN ESPECÍFICA PARA EDUCACIÓN}"
    display as text "{hline 60}"
    display as text "Configuración específica para variables educativas"
    display as text "Método: Thomas, Wang & Fan (2001)"
    display as text "{hline 60}"
    
    * Verificar que la variable existe
    capture confirm variable `variable'
    if _rc != 0 {
        display as error "Variable `variable' no encontrada en el dataset"
        exit 111
    }
    
    * Crear variable nivel_educ (1-8)
    capture drop _gini_value _gini_prop
    generate _gini_value = .
    generate _gini_prop = .
    
    display as text "Configurando variable educativa: `variable'"
    
    * Asignar niveles educativos según Thomas, Wang & Fan
    replace _gini_value = 0    if `variable' == 0              // Sin nivel
    replace _gini_value = 2.72 if inrange(`variable', 1, 5)    // Primaria incompleta
    replace _gini_value = 6    if `variable' == 6              // Primaria completa
    replace _gini_value = 8.48 if inrange(`variable', 7, 10)   // Secundaria incompleta
    replace _gini_value = 11   if `variable' == 11             // Secundaria completa
    replace _gini_value = 13.54 if inrange(`variable', 12, 15) // Superior incompleta
    replace _gini_value = 16.07 if inrange(`variable', 16, 17) // Superior completa
    replace _gini_value = 18   if `variable' >= 18             // Posgrado
    
    * Calcular proporciones
    quietly levelsof _gini_value, local(valores)
    foreach valor of local valores {
        count if _gini_value == `valor'
        replace _gini_prop = r(N) / _N if _gini_value == `valor'
    }
    
    * Etiquetar variables
    label variable _gini_value "Años de educación (Thomas et al.)"
    label variable _gini_prop "Proporción en cada nivel educativo"
    
    display as text "✓ Configuración educativa completada"
    display as text "✓ Valores Thomas et al. aplicados"
    display as text "{hline 60}"
    
    * Mostrar resumen
    display _n
    display as text "{bf:RESUMEN DE CONFIGURACIÓN EDUCATIVA:}"
    tabulate _gini_value, summarize(_gini_prop)
end

* ============================================================
* SUBPROGRAMA: GUARDAR RESULTADOS
* ============================================================
program define giniguardar
    args resultados save replace
    
    preserve
    clear
    
    mata: st_matrix("mat_resultados", `resultados')
    
    svmat mat_resultados
    rename (mat_resultados1 mat_resultados2 mat_resultados3 ///
            mat_resultados4 mat_resultados5 mat_resultados6) ///
           (nivel_grupo coeficiente_gini valor_promedio n_obs variable_grupo etiqueta_grupo)
    
    label variable nivel_grupo "Nivel del grupo analizado"
    label variable coeficiente_gini "Coeficiente de Gini"
    label variable valor_promedio "Valor promedio de la variable"
    label variable n_obs "Número de observaciones"
    label variable variable_grupo "Variable de agrupación"
    label variable etiqueta_grupo "Etiqueta del grupo"
    
    if "`replace'" != "" {
        save "`save'", replace
    }
    else {
        save "`save'"
    }
    
    display _n
    display as text "Resultados guardados en: " as result "`save'"
    restore
end

* ============================================================
* PROGRAMA AUXILIAR: RESUMEN EJECUTIVO
* ============================================================
program define giniresumen
    syntax [varlist] [if] [in], [MINobs(integer 30)]
    
    display _n
    display as text "{bf:ginivardiscreta - RESUMEN EJECUTIVO}"
    display as text "{hline 60}"
    display as text "Análisis rápido de desigualdad para variables discretas"
    display as text "{hline 60}"
    
    if "`varlist'" == "" {
        local varlist "region genero"
        display as text "Variables por defecto: region genero"
    }
    
    ginivardiscreta `varlist' `if' `in', minobs(`minobs')
end

* ============================================================
* PROGRAMA AUXILIAR: GRÁFICO DE RESULTADOS
* ============================================================
program define giniplot
    args varlist
    
    display _n
    display as text "{bf:ginivardiscreta - GRÁFICO DE RESULTADOS}"
    display as text "Función de gráficos disponible en próximas versiones"
    display as text "Use los resultados guardados para crear gráficos externos"
end

* ============================================================
* FIN DEL ARCHIVO ginivardiscreta.ado
* ============================================================
