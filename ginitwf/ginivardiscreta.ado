* ============================================================
* PROGRAMA: ginivardiscreta.ado
* PAQUETE: ginivardiscreta - Gini para Variables Discretas
* VERSIÓN: 1.0
* AUTOR: Washington Quintero Montaño
* INSTITUCIÓN: Universidad de Guayaquil
* EMAIL: washington.quinterom@ug.edu.ec
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
    display as text "{hline 78}"
end

* Los subprogramas restantes se mantienen igual...
* [El resto del código permanece igual que en la versión anterior]
