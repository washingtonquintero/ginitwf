* ============================================================
* PROGRAMA: ginivardiscreta.ado
* PAQUETE: ginivardiscreta - Gini para Variables Discretas
* VERSIÓN: 1.0
* AUTOR: Washington Quintero Montaño
* INSTITUCIÓN: Universidad de Guayaquil
* EMAIL: washington.quinterom@ug.edu.ec
* REPOSITORIO: github.com/washingtonquintero/ginitwf
* INSTALACIÓN: net install ginivardiscreta, from("https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/") replace
* MÉTODO: Thomas, Wang & Fan (2001)
* REFERENCIA: Cuenca & Urrutia (2019)
* ============================================================

program define ginivardiscreta
    version 14.0
    syntax varlist(min=1) [if] [in] , ///
        [MINobs(integer 100)]         ///
        [SHOWall]                     ///
        [REPLACE]                     ///
        [SAVE(string)]                ///
        [DETAILed]                    ///
        [PLOT]                        ///
        [LEVEL]
    
    * Display header
    display _n
    display as text "{hline 78}"
    display as text "{bf:ginivardiscreta - GINI PARA VARIABLES DISCRETAS}"
    display as text "{hline 78}"
    display as text "Metodología: {bf:Thomas, Wang & Fan (2001)}"
    display as text "Referencia:  Cuenca & Urrutia (2019) - RMIE"
    display as text "Autor:       Washington Quintero Montaño - UG"
    display as text "Repositorio: github.com/washingtonquintero/ginitwf"
    display as text "Instalación: net install ginivardiscreta, from(""https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/"") replace"
    display as text "Mínimo de observaciones: `minobs'"
    display as text "Variables analizadas: `varlist'"
    if "`if'`in'" != "" display as text "Filtro aplicado: `if' `in'"
    display as text "{hline 78}"
    
    preserve
    
    * Aplicar filtros si existen
    if "`if'`in'" != "" {
        keep `if' `in'
    }
    
    * Verificar variables requeridas
    capt confirm variable nivel_educ xi
    if _rc != 0 {
        display as error "{bf:ERROR:} Variables requeridas no encontradas."
        display as error "El paquete requiere las variables:"
        display as error "  - {bf:nivel_educ}: Nivel educativo (1-8)"
        display as error "  - {bf:xi}: Años de educación asignados"
        display as error ""
        display as error "Use {bf:ginisetup} para crear estas variables automáticamente."
        restore
        exit 111
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
            quietly count if `var' == `nivel' & !missing(nivel_educ, xi)
            local n_obs = r(N)
            
            if `n_obs' >= `minobs' {
                local grupos_validos = `grupos_validos' + 1
                
                * Calcular Gini para este grupo
                ginicalcular "`var'" `nivel' "`etiqueta'" `n_obs' "`resultados'" "`save'" "`level'"
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
* SUBPROGRAMA: CÁLCULO DEL GINI
* ============================================================
program define ginicalcular
    args var_grupo nivel etiqueta n_obs resultados save level
    
    quietly {
        preserve
        
        * Mantener solo el grupo actual
        keep if `var_grupo' == `nivel' & !missing(nivel_educ, xi)
        
        * Valores fijos según Thomas, Wang & Fan para Perú
        local xi1 0     // Sin nivel
        local xi2 2.72  // Primaria incompleta
        local xi3 6     // Primaria completa
        local xi4 8.48  // Secundaria incompleta
        local xi5 11    // Secundaria completa
        local xi6 13.54 // Superior incompleta
        local xi7 16.07 // Superior completa
        local xi8 18    // Posgrado
        
        * Calcular proporciones para cada nivel educativo
        local total_obs = _N
        forvalues i = 1/8 {
            count if nivel_educ == `i'
            local p`i' = r(N) / `total_obs'
        }
        
        * Calcular años promedio de educación
        local mu = 0
        forvalues i = 1/8 {
            local mu = `mu' + `p`i'' * `xi`i''
        }
        
        * Calcular sumatoria doble para Gini (ecuación Thomas et al.)
        local sumatoria = 0
        forvalues i = 1/8 {
            forvalues j = 1/`=`i'-1' {
                local diff = abs(`xi`i'' - `xi`j'')
                local producto = `p`i'' * `diff' * `p`j''
                local sumatoria = `sumatoria' + `producto'
            }
        }
        
        * Coeficiente de Gini educativo
        local gini = `sumatoria' / `mu'
        
        * Clasificar nivel de desigualdad
        if `gini' < 0.15 local des "BAJA"
        else if `gini' < 0.25 local des "MEDIA" 
        else if `gini' < 0.35 local des "ALTA"
        else local des "MUY ALTA"
        
        * Mostrar detalles por nivel si se solicita
        if "`level'" != "" {
            display as text "    Distribución por niveles:"
            forvalues i = 1/8 {
                local porcentaje = `p`i'' * 100
                local nivel_label : label nivel_educ `i'
                display as text "      `nivel_label': " as result %5.1f `porcentaje' "%"
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
        as result "Años: " %5.1f `mu' _col(70) "| " ///
        as result "N: `n_obs'"
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
           (nivel gini años_educ n_obs variable_grupo etiqueta_grupo)
    
    label variable nivel "Nivel del grupo"
    label variable gini "Coeficiente de Gini"
    label variable años_educ "Años promedio de educación"
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
* PROGRAMA AUXILIAR: CONFIGURACIÓN INICIAL
* ============================================================
program define ginisetup
    syntax, EDUCvar(string) [NOMBREvar(string)]
    
    display _n
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN INICIAL}"
    display as text "{hline 60}"
    display as text "Autor: Washington Quintero Montaño - Universidad de Guayaquil"
    display as text "Repositorio: github.com/washingtonquintero/ginitwf"
    display as text "{hline 60}"
    
    * Crear variable nivel_educ (1-8)
    capture drop nivel_educ
    generate nivel_educ = .
    
    * Asignar niveles educativos según la variable de educación
    display as text "Creando variable {bf:nivel_educ}..."
    
    replace nivel_educ = 1 if `educvar' == 0              // Sin nivel
    replace nivel_educ = 2 if inrange(`educvar', 1, 5)    // Primaria incompleta
    replace nivel_educ = 3 if `educvar' == 6              // Primaria completa
    replace nivel_educ = 4 if inrange(`educvar', 7, 10)   // Secundaria incompleta
    replace nivel_educ = 5 if `educvar' == 11             // Secundaria completa
    replace nivel_educ = 6 if inrange(`educvar', 12, 15)  // Superior incompleta
    replace nivel_educ = 7 if inrange(`educvar', 16, 17)  // Superior completa
    replace nivel_educ = 8 if `educvar' >= 18             // Posgrado
    
    * Crear variable xi con años de educación
    capture drop xi
    generate xi = .
    
    * Asignar valores según Thomas, Wang & Fan
    display as text "Creando variable {bf:xi} (años de educación)..."
    
    replace xi = 0    if nivel_educ == 1
    replace xi = 2.72 if nivel_educ == 2
    replace xi = 6    if nivel_educ == 3
    replace xi = 8.48 if nivel_educ == 4
    replace xi = 11   if nivel_educ == 5
    replace xi = 13.54 if nivel_educ == 6
    replace xi = 16.07 if nivel_educ == 7
    replace xi = 18   if nivel_educ == 8
    
    label variable nivel_educ "Nivel educativo (1-8)"
    label variable xi "Años de educación (Thomas et al.)"
    
    * Etiquetas de nivel_educ
    label define nivel_educ 1 "Sin nivel" 2 "Primaria incompleta" ///
        3 "Primaria completa" 4 "Secundaria incompleta" ///
        5 "Secundaria completa" 6 "Superior incompleta" ///
        7 "Superior completa" 8 "Posgrado"
    label values nivel_educ nivel_educ
    
    display as text "✓ Variable {bf:nivel_educ} creada y etiquetada"
    display as text "✓ Variable {bf:xi} creada con valores Thomas et al."
    display as text "✓ Paquete {bf:ginivardiscreta} listo para usar"
    display as text "{hline 60}"
    
    * Mostrar resumen
    display _n
    display as text "{bf:RESUMEN DE VARIABLES CREADAS:}"
    tabulate nivel_educ
    summarize xi, detail
end

* ============================================================
* PROGRAMA AUXILIAR: RESUMEN EJECUTIVO
* ============================================================
program define giniresumen
    syntax [varlist] [if] [in], [MINobs(integer 100)]
    
    display _n
    display as text "{bf:ginivardiscreta - RESUMEN EJECUTIVO}"
    display as text "{hline 60}"
    display as text "Autor: Washington Quintero Montaño - Universidad de Guayaquil"
    display as text "Repositorio: github.com/washingtonquintero/ginitwf"
    display as text "Análisis rápido de desigualdad educativa"
    display as text "{hline 60}"
    
    if "`varlist'" == "" {
        local varlist "area genero"
        display as text "Variables por defecto: area genero"
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
