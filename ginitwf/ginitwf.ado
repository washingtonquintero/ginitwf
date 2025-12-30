*! version 3.0.3 2025-03-30
*! Ginitwf: Gini coefficients with and without by()/weight() options
*! Author: Washington Quintero
*! Compatible with: Stata 14+
*! Repository: https://github.com/washingtonquintero/ginitwf

program define ginitwf, rclass
    version 14
    syntax varname [if] [in] [aweight fweight pweight iweight/] ///
        [, BY(varname) TYPE(string) LEVels(varname) XIvar(varname) ///
        EDUcational SAVing(string) REPLace noPRINT]
    
    marksample touse
    markout `touse' `by'
    
    * Mensaje informativo mejorado
    if ("`by'" != "" | "`weight'" != "") & "`noprint'" == "" {
        di as text _n "Nota: Usando opciones avanzadas"
        if "`by'" != "" {
            di as text "  - by(`by')"
        }
        if "`weight'" != "" {
            local peso_exp = subinstr(`"`exp'"', "=", "", 1)
            di as text "  - `weight'(`peso_exp')"
        }
    }
    
    * Determinar tipo de análisis
    if "`educational'" != "" {
        local type "discrete"
    }
    
    * Opción 1: CON by() - Análisis por grupos
    if "`by'" != "" {
        ginitwf_by `varlist' if `touse' `exp', ///
            by(`by') type(`type') levels(`levels') xivar(`xivar') ///
            saving(`saving') `replace' `noprint'
    }
    * Opción 2: SIN by() - Análisis general
    else {
        ginitwf_general `varlist' if `touse' `exp', ///
            type(`type') levels(`levels') xivar(`xivar') ///
            saving(`saving') `replace' `noprint'
    }
end

* ---------------------------------------------------------------------------
* 1. SUBPROGRAMA PARA ANÁLISIS POR GRUPOS (CON by())
* ---------------------------------------------------------------------------
program define ginitwf_by, rclass
    syntax varname [if] [in] [aweight fweight pweight iweight/] ///
        , BY(varname) [TYPE(string) LEVels(varname) XIvar(varname) ///
        SAVing(string) REPLace noPRINT]
    
    marksample touse
    
    * Crear variable de grupo
    tempvar group
    qui egen `group' = group(`by') if `touse', label
    qui sum `group' if `touse', meanonly
    local n_groups = r(max)
    
    * Mostrar encabezado
    if "`noprint'" != "noprint" {
        di _n as text "{hline 60}"
        di as text "COEFICIENTE GINI POR GRUPO: `by'"
        di as text "{hline 60}"
        di as text "Número de grupos: " as result `n_groups'
        di as text "Variable: " as result "`varlist'"
        if "`weight'" != "" {
            local peso_exp = subinstr(`"`exp'"', "=", "", 1)
            di as text "Peso: " as result "`weight'(`peso_exp')"
        }
        di as text "{hline 60}"
    }
    
    * Matriz para resultados
    tempname results_mat
    matrix `results_mat' = J(`n_groups', 6, .)
    matrix colnames `results_mat' = Grupo N Media Gini Min Max
    
    * Calcular para cada grupo
    forvalues g = 1/`n_groups' {
        * Obtener etiqueta del grupo
        levelsof `by' if `group' == `g', local(group_label) clean
        local group_label = subinstr(`"`group_label'"', `"""', "", .)
        
        if "`noprint'" != "noprint" {
            di as text _n "Grupo `g': `group_label'"
        }
        
        * Calcular Gini para este grupo
        if "`weight'" != "" {
            local wgt `"[`weight'`exp']"'
        }
        
        capture {
            if ("`type'" == "discrete" & "`levels'" != "" & "`xivar'" != "") {
                * Gini educativo (discreto)
                if "`weight'" != "" {
                    gini_discreto `varlist' if `touse' & `group' == `g' `wgt', ///
                        levels(`levels') xivar(`xivar') `noprint'
                }
                else {
                    gini_discreto `varlist' if `touse' & `group' == `g', ///
                        levels(`levels') xivar(`xivar') `noprint'
                }
            }
            else {
                * Gini continuo
                if "`weight'" != "" {
                    gini_continuo `varlist' if `touse' & `group' == `g' `wgt', `noprint'
                }
                else {
                    gini_continuo `varlist' if `touse' & `group' == `g', `noprint'
                }
            }
            
            * Almacenar resultados
            matrix `results_mat'[`g', 1] = `g'
            matrix `results_mat'[`g', 2] = r(N)
            matrix `results_mat'[`g', 3] = r(mean)
            matrix `results_mat'[`g', 4] = r(gini)
            matrix `results_mat'[`g', 5] = r(min)
            matrix `results_mat'[`g', 6] = r(max)
            
            if "`noprint'" != "noprint" {
                di as text "  Gini: " as result %8.4f r(gini) ///
                    as text "  Media: " as result %8.2f r(mean) ///
                    as text "  N: " as result r(N)
            }
        }
        
        if _rc != 0 {
            if "`noprint'" != "noprint" {
                di as error "  Error en cálculo"
            }
            matrix `results_mat'[`g', 1] = `g'
            matrix `results_mat'[`g', 2] = 0
            matrix `results_mat'[`g', 3] = .
            matrix `results_mat'[`g', 4] = .
        }
    }
    
    * Mostrar tabla resumen
    if "`noprint'" != "noprint" {
        di _n as text "{hline 60}"
        di as text "RESUMEN POR GRUPOS:"
        di as text "{hline 60}"
        matlist `results_mat', title("Coeficiente Gini por `by'") border(bottom)
    }
    
    * Guardar resultados si se solicita
    if "`saving'" != "" {
        preserve
        clear
        
        * Crear dataset con resultados
        svmat `results_mat', names(col)
        
        * Agregar etiquetas de grupo
        gen grupo_label = ""
        forvalues g = 1/`n_groups' {
            levelsof `by' if `group' == `g', local(label) clean
            local label = subinstr(`"`label'"', `"""', "", .)
            replace grupo_label = `"`label'"' if Grupo == `g'
        }
        
        label var Grupo "ID del grupo"
        label var grupo_label "Nombre del grupo"
        label var N "Observaciones"
        label var Media "Media"
        label var Gini "Coeficiente Gini"
        label var Min "Mínimo"
        label var Max "Máximo"
        
        save "`saving'", `replace'
        
        if "`noprint'" != "noprint" {
            di as green _n "Resultados guardados en: `saving'"
        }
        
        restore
    }
    
    * Retornar resultados
    return matrix results_by = `results_mat'
    return scalar n_groups = `n_groups'
    return local by_var "`by'"
end

* ---------------------------------------------------------------------------
* 2. SUBPROGRAMA PARA ANÁLISIS GENERAL (SIN by())
* ---------------------------------------------------------------------------
program define ginitwf_general, rclass
    syntax varname [if] [in] [aweight fweight pweight iweight/] ///
        [, TYPE(string) LEVels(varname) XIvar(varname) ///
        SAVing(string) REPLace noPRINT]
    
    marksample touse
    
    * Determinar tipo de análisis si no se especificó
    if "`type'" == "" {
        * Intentar inferir tipo
        qui tab `varlist' if `touse', matcell(freq)
        local unique_vals = r(r)
        
        if `unique_vals' <= 15 & "`levels'" != "" & "`xivar'" != "" {
            local type "discrete"
            if "`noprint'" != "noprint" {
                di as text "Nota: Tipo inferido como DISCRETE (valores únicos: `unique_vals')"
            }
        }
        else {
            local type "continuous"
            if "`noprint'" != "noprint" {
                di as text "Nota: Tipo inferido como CONTINUOUS (valores únicos: `unique_vals')"
            }
        }
    }
    
    * Realizar cálculo según tipo
    if "`type'" == "continuous" {
        * Gini continuo (Deaton, 1997)
        gini_continuo `varlist' if `touse' `exp', `noprint'
        
        if "`noprint'" != "noprint" {
            di _n as text "{title:Coeficiente de Gini (Deaton, 1997)}"
            di as text "{hline 50}"
            di as text "Variable: " as result "`varlist'"
            di as text "Observaciones: " as result r(N)
            if "`weight'" != "" {
                local peso_exp = subinstr(`"`exp'"', "=", "", 1)
                di as text "Peso utilizado: " as result "`weight'(`peso_exp')"
            }
            di as text "Media (μ): " as result %12.4f r(mean)
            di as text "Coeficiente de Gini: " as result %12.4f r(gini)
            di as text "{hline 50}"
        }
    }
    else if "`type'" == "discrete" {
        * Verificar variables requeridas
        if "`levels'" == "" | "`xivar'" == "" {
            di as error "Error: Para tipo DISCRETE, debe especificar: levels() y xivar()"
            exit 198
        }
        
        * Gini educativo (Thomas et al., 2001)
        gini_discreto `varlist' if `touse' `exp', ///
            levels(`levels') xivar(`xivar') `noprint'
        
        if "`noprint'" != "noprint" {
            di _n as text "{title:Coeficiente de Gini Educativo (Thomas, Wang & Fan, 2001)}"
            di as text "{hline 60}"
            di as text "Variable de años: " as result "`varlist'"
            di as text "Variable de nivel: " as result "`levels'"
            di as text "Variable xi: " as result "`xivar'"
            di as text "Observaciones: " as result r(N)
            if "`weight'" != "" {
                local peso_exp = subinstr(`"`exp'"', "=", "", 1)
                di as text "Peso utilizado: " as result "`weight'(`peso_exp')"
            }
            di as text "Media (μ): " as result %12.4f r(mean)
            di as text "Coeficiente de Gini: " as result %12.4f r(gini)
            di as text "{hline 60}"
        }
    }
    else {
        di as error "Tipo no reconocido. Use: continuous o discrete"
        exit 198
    }
    
    * Guardar resultados si se solicita
    if "`saving'" != "" {
        preserve
        clear
        set obs 1
        
        gen variable = "`varlist'"
        gen tipo = "`type'"
        gen N = r(N)
        gen media = r(mean)
        gen gini = r(gini)
        gen min = r(min)
        gen max = r(max)
        
        if "`type'" == "discrete" {
            gen niveles = r(niveles)
        }
        
        if "`weight'" != "" {
            local peso_exp = subinstr(`"`exp'"', "=", "", 1)
            gen peso_utilizado = "`weight'(`peso_exp')"
        }
        
        save "`saving'", `replace'
        
        if "`noprint'" != "noprint" {
            di as green _n "Resultados guardados en: `saving'"
        }
        
        restore
    }
    
    * Retornar resultados
    return scalar gini = r(gini)
    return scalar mean = r(mean)
    return scalar N = r(N)
    return scalar min = r(min)
    return scalar max = r(max)
    if "`type'" == "discrete" {
        return scalar niveles = r(niveles)
    }
    return local var "`varlist'"
    return local type "`type'"
    if "`type'" == "continuous" {
        return local method "Deaton (1997)"
    }
    else {
        return local method "Thomas, Wang & Fan (2001)"
    }
end

* ---------------------------------------------------------------------------
* 3. SUBPROGRAMA PARA GINI CONTINUO (CON/SIN PESOS)
* ---------------------------------------------------------------------------
program define gini_continuo, rclass
    syntax varname [if] [in] [aweight fweight pweight iweight/] [, noPRINT]
    
    marksample touse
    
    * Manejar pesos
    if "`weight'" == "" {
        * SIN pesos
        qui sum `varlist' if `touse', meanonly
        local mu = r(mean)
        local n = r(N)
        local sum_w = `n'
        local min = r(min)
        local max = r(max)
        
        if `mu' == 0 {
            if "`noprint'" != "noprint" {
                di as error "La media es cero, no se puede calcular Gini"
            }
            return scalar gini = .
            return scalar mean = 0
            return scalar N = `n'
            exit
        }
        
        * Cálculo SIN pesos (fórmula directa)
        preserve
        keep if `touse'
        keep `varlist'
        sort `varlist'
        
        gen orden = _n
        gen term = (2*orden - `n' - 1) * `varlist'
        qui sum term
        local numerador = r(sum)
        
        local gini = `numerador' / (`n' * (`n' - 1) * `mu')
        
        restore
    }
    else {
        * CON pesos
        tempvar w_var
        gen double `w_var' `exp' if `touse'
        
        qui sum `varlist' [iw=`w_var'] if `touse'
        local mu = r(mean)
        local sum_w = r(sum_w)
        local n = r(N)
        
        * Estadísticas mín/max (sin pesos para simplificar)
        qui sum `varlist' if `touse'
        local min = r(min)
        local max = r(max)
        
        if `mu' == 0 {
            if "`noprint'" != "noprint" {
                di as error "La media es cero, no se puede calcular Gini"
            }
            return scalar gini = .
            return scalar mean = 0
            return scalar N = `n'
            exit
        }
        
        * Cálculo CON pesos
        preserve
        keep if `touse'
        keep `varlist' `exp'
        
        * Crear variable de peso
        tempvar peso
        gen double `peso' `exp'
        
        * Ordenar
        sort `varlist'
        
        * Calcular acumulados
        tempvar w_acum w_acum2
        gen double `w_acum' = sum(`peso')
        gen double `w_acum2' = sum(`varlist' * `peso')
        
        * Fórmula ponderada
        local W = `w_acum'[_N]
        tempvar numerador
        gen double `numerador' = (2*`w_acum' - `peso' - `W') * `varlist' * `peso'
        qui sum `numerador'
        local num = r(sum)
        
        local gini = `num' / (`W' * `W' * `mu')
        
        restore
    }
    
    * Retornar resultados
    return scalar gini = `gini'
    return scalar mean = `mu'
    return scalar N = `n'
    return scalar sum_w = `sum_w'
    return scalar min = `min'
    return scalar max = `max'
end

* ---------------------------------------------------------------------------
* 4. SUBPROGRAMA PARA GINI DISCRETO (CON/SIN PESOS)
* ---------------------------------------------------------------------------
program define gini_discreto, rclass
    syntax varname [if] [in] [aweight fweight pweight iweight/] ///
        , LEVels(varname) XIvar(varname) [, noPRINT]
    
    marksample touse
    
    * Verificar que las variables existen
    confirm variable `levels' `xivar'
    
    * Manejar pesos
    if "`weight'" == "" {
        * SIN pesos
        preserve
        keep if `touse'
        keep `varlist' `levels' `xivar'
        
        * Verificar consistencia
        bysort `levels': egen double xi_check = sd(`xivar')
        qui sum xi_check
        if r(max) > 0.0001 {
            di as error "Error: xi no es constante por nivel educativo"
            exit 198
        }
        
        * Colapsar por nivel
        collapse (count) N = `varlist' (mean) xi_val = `xivar', by(`levels')
        
        * Calcular proporciones
        egen N_total = total(N)
        gen p_i = N / N_total
        
        * Ordenar por xi_val
        sort xi_val
        
        * Calcular media
        gen p_x = p_i * xi_val
        egen mu = total(p_x)
        
        * Calcular doble sumatoria
        local m = _N
        local suma = 0
        
        forvalues i = 1/`m' {
            forvalues j = 1/`m' {
                if `i' != `j' {
                    local dif = abs(xi_val[`i'] - xi_val[`j'])
                    local suma = `suma' + p_i[`i'] * p_i[`j'] * `dif'
                }
            }
        }
        
        * Calcular Gini
        local gini = `suma' / (2 * mu[1])
        
        * Estadísticas
        local n_obs = N_total[1]
        local min = xi_val[1]
        local max = xi_val[`m']
        
        restore
    }
    else {
        * CON pesos
        tempvar w_var
        gen double `w_var' `exp' if `touse'
        
        preserve
        keep if `touse'
        keep `varlist' `levels' `xivar' `exp'
        
        * Colapsar con pesos
        collapse (sum) peso = `exp' (mean) xi_val = `xivar', by(`levels')
        
        * Calcular proporciones ponderadas
        egen peso_total = total(peso)
        gen p_i = peso / peso_total
        
        * Ordenar por xi_val
        sort xi_val
        
        * Media ponderada
        gen p_x = p_i * xi_val
        egen mu = total(p_x)
        
        * Calcular doble sumatoria ponderada
        local m = _N
        local suma = 0
        
        forvalues i = 1/`m' {
            forvalues j = 1/`m' {
                if `i' != `j' {
                    local dif = abs(xi_val[`i'] - xi_val[`j'])
                    local suma = `suma' + p_i[`i'] * p_i[`j'] * `dif'
                }
            }
        }
        
        * Calcular Gini
        local gini = `suma' / (2 * mu[1])
        
        * Estadísticas
        local n_obs = peso_total[1]
        local min = xi_val[1]
        local max = xi_val[`m']
        
        restore
    }
    
    * Retornar resultados
    return scalar gini = `gini'
    return scalar mean = `mu'
    return scalar N = `n_obs'
    return scalar niveles = `m'
    return scalar min = `min'
    return scalar max = `max'
end

* ---------------------------------------------------------------------------
* 5. COMANDOS AUXILIARES
* ---------------------------------------------------------------------------

* 5.1 ginitwfsetup
program define ginitwfsetup
    version 14
    di _n as text "Configurando variables para Gini Educativo..."
    
    * Crear variable anios_educ a partir de p10a
    cap confirm variable p10a
    if _rc {
        di as yellow "Variable p10a no encontrada. Creando variables de ejemplo."
        gen anios_educ = floor(runiform()*19)
    }
    else {
        gen anios_educ = .
        replace anios_educ = 0 if inlist(p10a, 1, 2)
        replace anios_educ = 3 if p10a == 3
        replace anios_educ = 6 if p10a == 4
        replace anios_educ = 9 if p10a == 5
        replace anios_educ = 11 if p10a == 6
        replace anios_educ = 14 if p10a == 7
        replace anios_educ = 16 if p10a == 8
        replace anios_educ = 18 if p10a == 9
    }
    
    * Crear niveles educativos
    gen nivel_educ = .
    gen xi = .
    
    replace nivel_educ = 1 if anios_educ == 0
    replace xi = 0 if nivel_educ == 1
    
    replace nivel_educ = 2 if anios_educ >= 1 & anios_educ <= 5
    replace xi = 2.72 if nivel_educ == 2
    
    replace nivel_educ = 3 if anios_educ == 6
    replace xi = 6 if nivel_educ == 3
    
    replace nivel_educ = 4 if anios_educ >= 7 & anios_educ <= 10
    replace xi = 8.48 if nivel_educ == 4
    
    replace nivel_educ = 5 if anios_educ == 11
    replace xi = 11 if nivel_educ == 5
    
    replace nivel_educ = 6 if anios_educ >= 12 & anios_educ <= 15
    replace xi = 13.54 if nivel_educ == 6
    
    replace nivel_educ = 7 if anios_educ >= 16 & anios_educ <= 17
    replace xi = 16.07 if nivel_educ == 7
    
    replace nivel_educ = 8 if anios_educ >= 18
    replace xi = 18 if nivel_educ == 8
    
    * Etiquetar
    label var anios_educ "Años de educación"
    label var nivel_educ "Nivel educativo (1-8)"
    label var xi "Años promedio por nivel"
    
    label define niveles 1 "Sin nivel" 2 "Primaria inc." 3 "Primaria comp." ///
                        4 "Secundaria inc." 5 "Secundaria comp." ///
                        6 "Superior inc." 7 "Superior comp." 8 "Postgrado"
    label values nivel_educ niveles
    
    * Estadísticas descriptivas
    qui count if !missing(anios_educ)
    local n = r(N)
    
    qui sum anios_educ
    local mean_educ = r(mean)
    local sd_educ = r(sd)
    
    qui tab nivel_educ
    local n_levels = r(r)
    
    di as green "✓ Variables creadas: anios_educ, nivel_educ, xi"
    di _n as text "Use: ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)"
end

* 5.2 ginitwfeduc
program define ginitwfeduc
    version 14
    syntax [if] [in] [aweight fweight/] [, BY(varname) AGE(integer 25)]
    
    * Verificar variables
    cap confirm variable anios_educ nivel_educ xi
    if _rc {
        di as error "Ejecute ginitwfsetup primero"
        exit 111
    }
    
    * Filtrar por edad
    if "`if'`in'" != "" {
        local filtro `if' `in' & edad >= `age'
    }
    else {
        local filtro if edad >= `age'
    }
    
    di _n as text "Calculando Gini Educativo para población >= `age' años"
    
    if "`by'" != "" {
        ginitwf anios_educ `filtro' `exp', by(`by') type(discrete) ///
            levels(nivel_educ) xivar(xi)
    }
    else {
        ginitwf anios_educ `filtro' `exp', type(discrete) ///
            levels(nivel_educ) xivar(xi)
    }
end

* 5.3 ginitwfresumen
program define ginitwfresumen
    version 14
    syntax [, SAVe(string) REPLACE]
    
    if "`r(type)'" == "" {
        di as error "No hay resultados. Ejecute ginitwf primero."
        exit 301
    }
    
    di _n as text "="*60
    di as text "RESUMEN DE RESULTADOS GINI"
    di as text "="*60
    
    di as text "Método: " as result "`r(method)'"
    di as text "Tipo: " as result "`r(type)'"
    di as text "Variable: " as result "`r(var)'"
    di as text "Observaciones: " as result r(N)
    di as text "Media (μ): " as result %9.4f r(mean)
    di as text "Coeficiente Gini: " as result %9.4f r(gini)
    
    if "`r(type)'" == "discrete" {
        di as text "Niveles educativos: " as result r(niveles)
    }
    
    di as text "Rango: " as result r(min) " - " r(max)
    
    * Interpretación
    di _n as text "Interpretación:"
    if r(gini) < 0.2 {
        di as text "  Desigualdad: " as green "BAJA"
    }
    else if r(gini) < 0.4 {
        di as text "  Desigualdad: " as yellow "MODERADA"
    }
    else if r(gini) < 0.6 {
        di as text "  Desigualdad: " as red "ALTA"
    }
    else {
        di as text "  Desigualdad: " as red "MUY ALTA"
    }
    
    * Guardar si se solicita
    if "`save'" != "" {
        preserve
        clear
        set obs 1
        
        gen metodo = "`r(method)'"
        gen tipo = "`r(type)'"
        gen variable = "`r(var)'"
        gen N = r(N)
        gen media = r(mean)
        gen gini = r(gini)
        gen min = r(min)
        gen max = r(max)
        
        if "`r(type)'" == "discrete" {
            gen niveles = r(niveles)
        }
        
        save "`save'", `replace'
        di as green _n "Resultados guardados en: `save'"
        restore
    }
end

* 5.4 ginitwfhelp
program define ginitwfhelp
    version 14
    di _n
    di as text "GINITWF - VERSIÓN 3.0.3 (COMPATIBLE)"
    di as text "=================================="
    di _n
    di as text "COMANDOS DISPONIBLES:"
    di _n
    di as text "  1. " as result "ginitwf varname [if] [in] [weight] [, options]"
    di as text "     Calcula coeficiente Gini (con/sin by()/weight())"
    di _n
    di as text "  2. " as result "ginitwfsetup"
    di as text "     Prepara variables para análisis educativo"
    di _n
    di as text "  3. " as result "ginitwfeduc [weight] [, by(varname) age(#)]"
    di as text "     Calcula Gini educativo simplificado"
    di _n
    di as text "  4. " as result "ginitwfresumen [, save(archivo) replace]"
    di as text "     Muestra y guarda resultados"
    di _n
    di as text "  5. " as result "ginitwfhelp"
    di as text "     Muestra esta ayuda"
    di _n
    di as text "OPCIONES PRINCIPALES PARA ginitwf:"
    di _n
    di as text "  type(continuous|discrete)  - Tipo de variable"
    di as text "  levels(varname)           - Variable de niveles (para discrete)"
    di as text "  xivar(varname)            - Variable xi (para discrete)"
    di as text "  by(varname)               - Calcular por grupos"
    di as text "  weight                    - Usar pesos muestrales"
    di as text "  saving(archivo)           - Guardar resultados"
    di as text "  replace                   - Reemplazar archivo existente"
    di as text "  noprint                   - No mostrar resultados en pantalla"
    di _n
    di as text "EJEMPLOS DE USO:"
    di _n
    di as text "  A) " as result "SIN by()/weight() (modo original):"
    di as result "     . ginitwf educ, type(continuous)"
    di as result "     . ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)"
    di _n
    di as text "  B) " as result "CON by() y weight():"
    di as result "     . ginitwf educ [aw=peso], by(region)"
    di as result "     . ginitwf anios_educ [aw=peso], by(area) type(discrete) levels(nivel_educ) xivar(xi)"
    di _n
    di as text "  C) " as result "Usando comandos auxiliares:"
    di as result "     . ginitwfsetup"
    di as result "     . ginitwfeduc if edad >= 25, by(quintil)"
    di as result "     . ginitwfresumen, save(resultados.dta)"
    di _n
    di as text "MÉTODOS IMPLEMENTADOS:"
    di as text "  - Deaton, A. (1997): Variables continuas"
    di as text "  - Thomas, Wang & Fan (2001): Variables discretas (Gini Educativo)"
    di _n
    di as text "REPOSITORIO: https://github.com/washingtonquintero/ginitwf"
    di as text "AUTOR: Washington Quintero - Universidad de Guayaquil"
    di as text "VERSIÓN: 3.0.3 (30 Marzo 2025)"
end
