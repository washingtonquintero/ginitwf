* ============================================================
* PROGRAMA: ginivardiscreta.ado
* PAQUETE: ginivardiscreta - Gini para Variables Discretas
* VERSIÓN: 2.2
* AUTOR: Washington Quintero Montaño - Universidad de Guayaquil
* ============================================================

* PROGRAMA PRINCIPAL - debe ir PRIMERO para evitar problemas
program define ginivardiscreta
    version 14.0
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
    
    display _n
    display as text "{hline 78}"
    display as text "{bf:ginivardiscreta - GINI PARA VARIABLES DISCRETAS}"
    display as text "{hline 78}"
    
    preserve
    
    * Aplicar filtros
    if "`if'`in'" != "" keep `if' `in'
    
    * Verificar configuración
    if "`noconfig'" == "" {
        capture confirm variable _gini_value _gini_prop
        if _rc != 0 {
            display as error "Variables _gini_value o _gini_prop no encontradas."
            display as error "Use: {bf:ginisetup, variable(anios_educ)}"
            restore
            exit 111
        }
    }
    
    * Procesar cada variable
    foreach var of local varlist {
        display _n "ANÁLISIS POR: `var'"
        display "{hline 60}"
        
        quietly levelsof `var', local(niveles)
        local grupos_validos = 0
        
        foreach nivel of local niveles {
            local etiqueta : label (`var') `nivel'
            if "`etiqueta'" == "" local etiqueta "`nivel'"
            
            quietly count if `var' == `nivel' & !missing(_gini_value, _gini_prop)
            local n_obs = r(N)
            
            if `n_obs' >= `minobs' {
                local grupos_validos = `grupos_validos' + 1
                ginicalcular "`var'" `nivel' "`etiqueta'" `n_obs'
            }
        }
        
        display "{hline 60}"
        display "Grupos válidos: `grupos_validos' de `: word count `niveles''"
    }
    
    restore
    display _n "CÁLCULO COMPLETADO"
end

* ============================================================
* PROGRAMA DE CONFIGURACIÓN - NUEVO NOMBRE: ginisetup
* ============================================================
program define ginisetup
    syntax, VARiable(string) [AUTOmatic]
    
    display _n
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN}"
    display as text "{hline 60}"
    
    * Verificar variable
    capture confirm variable `variable'
    if _rc != 0 {
        display as error "Variable `variable' no encontrada"
        exit 111
    }
    
    * Crear variables
    capture drop _gini_value _gini_prop
    generate _gini_value = `variable'
    generate _gini_prop = 1
    
    label variable _gini_value "Valor para cálculo Gini"
    label variable _gini_prop "Proporción"
    
    display "✓ Configuración completada para: `variable'"
    display "✓ Use: {bf:ginivardiscreta} variable_grupo"
    display "{hline 60}"
end

* ============================================================
* PROGRAMA DE CONFIGURACIÓN EDUCATIVA
* ============================================================
program define ginieducacion
    syntax, VARiable(string)
    
    display _n
    display as text "{bf:ginivardiscreta - CONFIGURACIÓN EDUCATIVA}"
    display as text "{hline 60}"
    
    * Verificar variable
    capture confirm variable `variable'
    if _rc != 0 {
        display as error "Variable `variable' no encontrada"
        exit 111
    }
    
    * Crear variables
    capture drop _gini_value _gini_prop
    generate _gini_value = .
    generate _gini_prop = .
    
    * Asignar valores educativos (Thomas et al.)
    replace _gini_value = 0    if `variable' == 0
    replace _gini_value = 2.72 if inrange(`variable', 1, 5)
    replace _gini_value = 6    if `variable' == 6
    replace _gini_value = 8.48 if inrange(`variable', 7, 10)
    replace _gini_value = 11   if `variable' == 11
    replace _gini_value = 13.54 if inrange(`variable', 12, 15)
    replace _gini_value = 16.07 if inrange(`variable', 16, 17)
    replace _gini_value = 18   if `variable' >= 18
    
    * Calcular proporciones
    quietly levelsof _gini_value, local(valores)
    foreach valor of local valores {
        count if _gini_value == `valor'
        replace _gini_prop = r(N) / _N if _gini_value == `valor'
    }
    
    label variable _gini_value "Años educación (Thomas et al.)"
    label variable _gini_prop "Proporción"
    
    display "✓ Configuración educativa completada"
    display "✓ Use: {bf:ginivardiscreta} variable_grupo"
    display "{hline 60}"
end

* ============================================================
* SUBPROGRAMA: CÁLCULO DEL GINI
* ============================================================
program define ginicalcular
    args var_grupo nivel etiqueta n_obs
    
    quietly {
        preserve
        keep if `var_grupo' == `nivel' & !missing(_gini_value, _gini_prop)
        
        * Obtener valores únicos
        quietly tabulate _gini_value, matrow(valores_unicos)
        local n_valores = r(r)
        
        * Calcular proporciones
        matrix proporciones_mat = J(`n_valores', 1, .)
        forvalues i = 1/`n_valores' {
            local valor = valores_unicos[`i', 1]
            count if _gini_value == `valor'
            matrix proporciones_mat[`i', 1] = r(N) / _N
        }
        
        * Calcular promedio
        local mu = 0
        forvalues i = 1/`n_valores' {
            local valor = valores_unicos[`i', 1]
            local prop = proporciones_mat[`i', 1]
            local mu = `mu' + `valor' * `prop'
        }
        
        * Calcular Gini
        local sumatoria = 0
        forvalues i = 1/`n_valores' {
            forvalues j = 1/`=`i'-1' {
                local valor_i = valores_unicos[`i', 1]
                local valor_j = valores_unicos[`j', 1]
                local prop_i = proporciones_mat[`i', 1]
                local prop_j = proporciones_mat[`j', 1]
                local sumatoria = `sumatoria' + `prop_i' * abs(`valor_i' - `valor_j') * `prop_j'
            }
        }
        
        local gini = `sumatoria' / `mu'
        
        * Clasificar
        if `gini' < 0.2 local des "BAJA"
        else if `gini' < 0.35 local des "MEDIA" 
        else if `gini' < 0.5 local des "ALTA"
        else local des "MUY ALTA"
        
        restore
    }
    
    display "  `etiqueta' | Gini: `: disp %6.4f `gini'' (`des') | Promedio: `: disp %5.2f `mu'' | N: `n_obs'"
end

* ============================================================
* FIN DEL ARCHIVO
* ============================================================
