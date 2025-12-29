*! version 2.0.0 2025-03-30
*! Calcula coeficiente de Gini con opciones by() y weight()
*! Autores: Basado en Deaton (1997) y Thomas, Wang & Fan (2001)

program define ginitwf, rclass
    version 14
    syntax varname [if] [in] [aweight fweight pweight iweight/] [, BY(varname) TYPE(string) LEVels(varname) XIvar(varname) EDUcational]
    
    marksample touse
    markout `touse' `by'
    
    * Verificar si hay pesos
    if "`weight'" != "" {
        local wtype `weight'
        local wexp `"=`exp'"'
        local wgt `"[`weight'`exp']"'
    }
    
    * Si hay by, calcular para cada grupo
    if "`by'" != "" {
        tempname results_by
        tempvar group
        egen `group' = group(`by') if `touse'
        qui sum `group' if `touse', meanonly
        local n_groups = r(max)
        
        di _n as text "Cálculo de Gini por grupos: `by'"
        di as text "Número de grupos: " as result `n_groups'
        
        matrix `results_by' = J(`n_groups', 4, .)
        matrix colnames `results_by' = Grupo N Media Gini
        matrix rownames `results_by' = Grupos
        
        forvalues g = 1/`n_groups' {
            di _n as text "Grupo `g':"
            capture {
                if "`weight'" != "" {
                    ginitwf_calc `varlist' if `touse' & `group' == `g' `wgt', ///
                        type(`type') levels(`levels') xivar(`xivar') educational(`educational')
                }
                else {
                    ginitwf_calc `varlist' if `touse' & `group' == `g', ///
                        type(`type') levels(`levels') xivar(`xivar') educational(`educational')
                }
                
                matrix `results_by'[`g', 1] = `g'
                matrix `results_by'[`g', 2] = r(N)
                matrix `results_by'[`g', 3] = r(mean)
                matrix `results_by'[`g', 4] = r(gini)
            }
        }
        
        di _n as text "RESUMEN POR GRUPOS:"
        matlist `results_by', title("Resultados por grupo de `by'")
        
        return matrix results_by = `results_by'
        exit
    }
    
    * Si no hay by, calcular para toda la muestra
    if "`weight'" != "" {
        ginitwf_calc `varlist' if `touse' `wgt', ///
            type(`type') levels(`levels') xivar(`xivar') educational(`educational')
    }
    else {
        ginitwf_calc `varlist' if `touse', ///
            type(`type') levels(`levels') xivar(`xivar') educational(`educational')
    }
end

program define ginitwf_calc, rclass
    version 14
    syntax varname [if] [in] [aweight fweight pweight iweight/] [, TYPE(string) LEVels(varname) XIvar(varname) EDUcational]
    
    marksample touse
    
    * Determinar tipo de análisis
    if "`educational'" != "" {
        local type "discrete"
    }
    
    if "`type'" == "" {
        qui tab `varlist' if `touse', matcell(freq)
        local unique_vals = r(r)
        
        if `unique_vals' <= 15 & "`levels'" != "" & "`xivar'" != "" {
            local type "discrete"
        }
        else {
            local type "continuous"
        }
    }
    
    if "`type'" == "continuous" {
        gincontinuous_ext `varlist' if `touse' `exp'
    }
    else if "`type'" == "discrete" {
        if "`levels'" == "" | "`xivar'" == "" {
            di as error "Para tipo DISCRETE, debe especificar: levels() y xivar()"
            exit 198
        }
        ginidiscrete_ext `varlist' if `touse' `exp', levelvar(`levels') xivar(`xivar')
    }
end

program define gincontinuous_ext, rclass
    syntax varname [if] [in] [aweight fweight pweight iweight/]
    
    marksample touse
    
    * Manejar pesos
    if "`weight'" == "" {
        local weight "aweight"
        tempvar w
        gen `w' = 1
        local exp `"=`w'"'
    }
    
    * Calcular estadísticas con pesos
    qui sum `varlist' if `touse' [`weight'`exp'], meanonly
    local mu = r(mean)
    local sum_w = r(sum_w)
    local n = r(N)
    
    if `mu' == 0 {
        di as error "La media es cero, no se puede calcular Gini"
        exit 198
    }
    
    * Preparar datos
    tempvar w_var sorted_w sum_w_i xi
    qui {
        gen `w_var' `exp' if `touse'
        sort `varlist'
        by `varlist': egen `sorted_w' = total(`w_var')
        gen `sum_w_i' = sum(`sorted_w')
        gen `xi' = `varlist' * `sorted_w'
    }
    
    * Calcular Gini con fórmula ponderada
    qui sum `xi' if `touse', meanonly
    local sum_xi = r(sum)
    
    * Fórmula: G = [2/(n²μ)] Σ_i Σ_j w_i w_j |x_i - x_j|
    * Implementación eficiente con pesos
    tempvar cum_w
    qui gen double `cum_w' = sum(`sorted_w') if `touse'
    
    * Calcular numerador
    tempvar numerador
    qui gen double `numerador' = (2 * `cum_w' - `sorted_w' - `sum_w') * `xi' if `touse'
    qui sum `numerador' if `touse', meanonly
    local num = r(sum)
    
    local gini = `num' / (`sum_w'^2 * `mu')
    
    * Mostrar resultados
    di _n as text "Coeficiente de Gini (Deaton, 1997)"
    di as text "Variable: " as result "`varlist'"
    di as text "Observaciones: " as result `n'
    if "`weight'" != "aweight" | "`weight'" == "aweight" & "`exp'" != "=1" {
        di as text "Suma de pesos: " as result %9.2f `sum_w'
    }
    di as text "Media (μ): " as result %9.4f `mu'
    di as text "Coeficiente de Gini: " as result %9.4f `gini'
    
    * Guardar resultados
    return scalar gini = `gini'
    return scalar mean = `mu'
    return scalar N = `n'
    return scalar sum_w = `sum_w'
    return local var "`varlist'"
    return local method "Deaton (1997)"
    return local type "continuous"
end

program define ginidiscrete_ext, rclass
    syntax varname [if] [in] [aweight fweight pweight iweight/], LEVelvar(varname) XIvar(varname)
    
    marksample touse
    
    * Manejar pesos
    if "`weight'" == "" {
        local weight "aweight"
        tempvar w
        gen `w' = 1
        local exp `"=`w'"'
    }
    
    preserve
    
    * Mantener solo observaciones relevantes
    qui keep if `touse'
    keep `varlist' `levelvar' `xivar' `exp'
    
    * Verificar que xi sea constante por nivel
    bysort `levelvar': egen double xi_check = sd(`xivar')
    qui sum xi_check
    if r(max) > 0.0001 {
        di as error "Error: xi no es constante por nivel educativo"
        exit 198
    }
    drop xi_check
    
    * Colapsar por nivel con pesos
    collapse (sum) peso = `exp' (mean) xi_val = `xivar', by(`levelvar')
    
    * Calcular total de pesos
    qui sum peso
    local total_peso = r(sum)
    
    * Calcular proporciones ponderadas
    gen double p_i = peso / `total_peso'
    
    * Ordenar por xi_val
    sort xi_val
    
    * Número de niveles
    local m = _N
    
    * Calcular media ponderada
    gen double p_x = p_i * xi_val
    qui sum p_x
    local mu = r(sum)
    
    * Calcular doble sumatoria con pesos
    tempvar sumatoria
    gen double `sumatoria' = 0
    
    forvalues i = 1/`m' {
        forvalues j = 1/`m' {
            if `i' != `j' {
                local dif = abs(xi_val[`i'] - xi_val[`j'])
                replace `sumatoria' = `sumatoria' + p_i[`i'] * p_i[`j'] * `dif' in `i'
            }
        }
    }
    
    qui sum `sumatoria'
    local suma_total = r(sum)
    
    * Calcular Gini educativo
    local gini_educ = (1/(2*`mu')) * `suma_total'
    
    restore
    
    * Mostrar resultados
    di _n as text "Coeficiente de Gini Educativo (Thomas, Wang & Fan, 2001)"
    di as text "Variable de años: " as result "`varlist'"
    di as text "Variable de nivel: " as result "`levelvar'"
    di as text "Variable xi: " as result "`xivar'"
    di as text "Niveles educativos: " as result `m'
    di as text "Observaciones ponderadas: " as result %9.2f `total_peso'
    di as text "Media ponderada (μ): " as result %9.4f `mu'
    di as text "Gini Educativo: " as result %9.4f `gini_educ'
    
    * Guardar resultados
    return scalar gini = `gini_educ'
    return scalar mean = `mu'
    return scalar N = `total_peso'
    return scalar niveles = `m'
    return local var "`varlist'"
    return local method "Thomas, Wang & Fan (2001)"
    return local type "discrete"
end

* Los comandos auxiliares permanecen igual (ginitwfsetup, ginitwfeduc, etc.)
* ... (mantén el resto del código igual)
