*! version 2.0.0 2025-03-30
*! Ginitwf: Gini coefficients for continuous and discrete variables
*! Authors: Washington Quintero
*! Based on: Deaton (1997) and Thomas, Wang & Fan (2001)
*! Repository: https://github.com/washingtonquintero/ginitwf

program define ginitwf, rclass
    version 14
    syntax varname [if] [in] [aweight fweight pweight iweight/] ///
        [, BY(varname) TYPE(string) LEVels(varname) XIvar(varname) EDUcational ///
        SAVing(string) REPLACE noPRINT]
    
    marksample touse
    markout `touse' `by'
    
    * Verificar opciones de guardado
    if "`saving'" != "" {
        confirm new file "`saving'"
    }
    
    * Manejo de pesos
    if "`weight'" != "" {
        local wtype `weight'
        local wexp `"=`exp'"'
        local wgt `"[`weight'`exp']"'
    }
    
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
    
    * Análisis por grupos
    if "`by'" != "" {
        tempname results_by
        tempvar group
        qui egen `group' = group(`by') if `touse', label
        qui sum `group' if `touse', meanonly
        local n_groups = r(max)
        
        if "`print'" != "noprint" {
            di _n as text "{title:Gini coefficients by group: `by'}"
            di as text "Number of groups: " as result `n_groups'
            di as text "{hline 60}"
        }
        
        matrix `results_by' = J(`n_groups', 6, .)
        matrix colnames `results_by' = Group N SumW Mean Gini Type
        matrix rownames `results_by' = `by'
        
        * Lista para almacenar etiquetas
        local group_labels ""
        
        forvalues g = 1/`n_groups' {
            * Obtener etiqueta del grupo
            levelsof `by' if `group' == `g', local(group_label) clean
            local group_labels `"`group_labels' `g'="`group_label'""'
            
            if "`print'" != "noprint" {
                di as text "Group `g' (`group_label'):"
            }
            
            capture {
                if "`weight'" != "" {
                    ginitwf_calc `varlist' if `touse' & `group' == `g' `wgt', ///
                        type(`type') levels(`levels') xivar(`xivar') noprint
                }
                else {
                    ginitwf_calc `varlist' if `touse' & `group' == `g', ///
                        type(`type') levels(`levels') xivar(`xivar') noprint
                }
                
                matrix `results_by'[`g', 1] = `g'
                matrix `results_by'[`g', 2] = r(N)
                matrix `results_by'[`g', 3] = r(sum_w)
                matrix `results_by'[`g', 4] = r(mean)
                matrix `results_by'[`g', 5] = r(gini)
                matrix `results_by'[`g', 6] = cond("`type'" == "discrete", 2, 1)
                
                if "`print'" != "noprint" {
                    di as text "    Gini: " as result %9.4f r(gini) ///
                        as text ", Mean: " as result %9.4f r(mean) ///
                        as text ", N: " as result r(N)
                }
            }
            
            if _rc != 0 & "`print'" != "noprint" {
                di as error "    Could not calculate for group `g'"
            }
        }
        
        if "`print'" != "noprint" {
            di as text "{hline 60}"
            di _n
            matlist `results_by', title("Results by `by'")
        }
        
        * Guardar resultados si se solicita
        if "`saving'" != "" {
            preserve
            clear
            svmat `results_by', names(col)
            
            * Agregar etiquetas de grupo
            gen group_label = ""
            forvalues g = 1/`n_groups' {
                local label: word `g' of `group_labels'
                local label = subinstr("`label'", "`g'=", "", 1)
                local label = subinstr(`"`label'"', `"""', "", .)
                replace group_label = `"`label'"' if Group == `g'
            }
            
            label var Group "Group ID"
            label var group_label "Group label"
            label var N "Number of observations"
            label var SumW "Sum of weights"
            label var Mean "Mean of `varlist'"
            label var Gini "Gini coefficient"
            label var Type "1=Continuous, 2=Discrete"
            
            save "`saving'", `replace'
            if "`print'" != "noprint" {
                di as green "Results saved to: `saving'"
            }
            restore
        }
        
        return matrix results_by = `results_by'
        return scalar n_groups = `n_groups'
        return local by_var "`by'"
        exit
    }
    
    * Análisis para toda la muestra
    if "`weight'" != "" {
        ginitwf_calc `varlist' if `touse' `wgt', ///
            type(`type') levels(`levels') xivar(`xivar')
    }
    else {
        ginitwf_calc `varlist' if `touse', ///
            type(`type') levels(`levels') xivar(`xivar')
    }
    
    * Guardar resultados individuales si se solicita
    if "`saving'" != "" {
        preserve
        clear
        set obs 1
        gen variable = "`varlist'"
        gen N = r(N)
        gen sum_w = r(sum_w)
        gen mean = r(mean)
        gen gini = r(gini)
        gen type = cond("`type'" == "discrete", "Discrete", "Continuous")
        gen method = r(method)
        
        save "`saving'", `replace'
        if "`print'" != "noprint" {
            di as green "Results saved to: `saving'"
        }
        restore
    }
end

program define ginitwf_calc, rclass
    version 14
    syntax varname [if] [in] [aweight fweight pweight iweight/] ///
        [, TYPE(string) LEVels(varname) XIvar(varname) noPRINT]
    
    marksample touse
    
    * Determinar tipo si no se especificó
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
    
    * Llamar al subprograma correspondiente
    if "`type'" == "continuous" {
        gincontinuous_calc `varlist' if `touse' `exp', noprint(`noprint')
    }
    else if "`type'" == "discrete" {
        if "`levels'" == "" | "`xivar'" == "" {
            di as error "For DISCRETE type, you must specify: levels() and xivar()"
            exit 198
        }
        ginidiscrete_calc `varlist' if `touse' `exp', ///
            levelvar(`levels') xivar(`xivar') noprint(`noprint')
    }
end

program define gincontinuous_calc, rclass
    syntax varname [if] [in] [aweight fweight pweight iweight/] [, noPRINT]
    
    marksample touse
    
    * Manejar pesos
    if "`weight'" == "" {
        local weight "aweight"
        tempvar w
        gen `w' = 1
        local exp `"=`w'"'
        local unweighted 1
    }
    else {
        local unweighted 0
    }
    
    * Calcular estadísticas básicas
    qui sum `varlist' if `touse' [`weight'`exp']
    local mu = r(mean)
    local sum_w = r(sum_w)
    local n = r(N)
    local sd = r(sd)
    
    if `mu' == 0 {
        if "`noprint'" != "noprint" {
            di as error "Mean is zero, cannot calculate Gini"
        }
        return scalar gini = .
        return scalar mean = 0
        return scalar N = `n'
        return scalar sum_w = `sum_w'
        exit
    }
    
    * Preparar datos para cálculo eficiente
    preserve
    keep if `touse'
    keep `varlist' `exp'
    
    * Crear variable de peso
    tempvar w_var
    gen double `w_var' `exp'
    
    * Ordenar por la variable de interés
    sort `varlist'
    
    * Calcular estadísticas acumuladas
    tempvar cum_w cum_wx
    gen double `cum_w' = sum(`w_var')
    gen double `cum_wx' = sum(`varlist' * `w_var')
    
    * Cálculo eficiente del Gini ponderado
    * G = [Σ_i (2*F_i - w_i - W) * x_i * w_i] / (W² * μ)
    * donde F_i es el peso acumulado hasta i
    local W = `cum_w'[_N]  // Suma total de pesos
    local T = `cum_wx'[_N] // Suma total de x*w
    
    tempvar Fi term
    gen double `Fi' = `cum_w' - 0.5 * `w_var'
    gen double `term' = (2 * `Fi' - `W') * `varlist' * `w_var'
    
    qui sum `term'
    local numerator = r(sum)
    
    local gini = `numerator' / (`W' * `T')
    
    restore
    
    * Mostrar resultados
    if "`noprint'" != "noprint" {
        di _n as text "{title:Gini Coefficient (Deaton, 1997)}"
        di as text "{hline 50}"
        di as text "Variable:     " as result "`varlist'"
        di as text "Type:         " as result "Continuous"
        di as text "Observations: " as result `n'
        
        if !`unweighted' {
            di as text "Sum of weights: " as result %12.2f `sum_w'
        }
        
        di as text "Mean (μ):      " as result %12.4f `mu'
        di as text "Std. Dev.:     " as result %12.4f `sd'
        di as text "Gini:          " as result %12.4f `gini'
        di as text "{hline 50}"
        
        * Interpretación
        di _n as text "Interpretation:"
        if `gini' < 0.2 {
            di as text "  Inequality level: " as green "LOW"
        }
        else if `gini' < 0.4 {
            di as text "  Inequality level: " as yellow "MODERATE"
        }
        else if `gini' < 0.6 {
            di as text "  Inequality level: " as red "HIGH"
        }
        else {
            di as text "  Inequality level: " as red "VERY HIGH"
        }
    }
    
    * Devolver resultados
    return scalar gini = `gini'
    return scalar mean = `mu'
    return scalar N = `n'
    return scalar sum_w = `sum_w'
    return scalar sd = `sd'
    return local var "`varlist'"
    return local method "Deaton (1997)"
    return local type "continuous"
end

program define ginidiscrete_calc, rclass
    syntax varname [if] [in] [aweight fweight pweight iweight/], ///
        LEVelvar(varname) XIvar(varname) [, noPRINT]
    
    marksample touse
    
    * Manejar pesos
    if "`weight'" == "" {
        local weight "aweight"
        tempvar w
        gen `w' = 1
        local exp `"=`w'"'
        local unweighted 1
    }
    else {
        local unweighted 0
    }
    
    preserve
    keep if `touse'
    keep `varlist' `levelvar' `xivar' `exp'
    
    * Verificar que xi sea constante por nivel
    bysort `levelvar': egen double xi_check = sd(`xivar')
    qui sum xi_check
    if r(max) > 0.0001 {
        if "`noprint'" != "noprint" {
            di as error "Error: xi is not constant by educational level"
        }
        restore
        exit 198
    }
    drop xi_check
    
    * Colapsar por nivel con pesos
    collapse (sum) peso = `exp' (mean) xi_val = `xivar', by(`levelvar')
    
    * Calcular total de pesos
    qui sum peso
    local total_peso = r(sum)
    local n_levels = _N
    
    if `total_peso' == 0 {
        if "`noprint'" != "noprint" {
            di as error "Total weight is zero"
        }
        restore
        return scalar gini = .
        exit
    }
    
    * Calcular proporciones ponderadas
    gen double p_i = peso / `total_peso'
    
    * Ordenar por xi_val (ascendente)
    sort xi_val
    
    * Calcular media ponderada
    gen double p_x = p_i * xi_val
    qui sum p_x
    local mu = r(sum)
    
    if `mu' == 0 {
        if "`noprint'" != "noprint" {
            di as error "Weighted mean is zero, cannot calculate Gini"
        }
        restore
        return scalar gini = .
        exit
    }
    
    * Calcular doble sumatoria: ΣΣ p_i * p_j * |x_i - x_j|
    * Implementación eficiente con Mata
    mata: mata clear
    mata: p = st_data(., "p_i")
    mata: x = st_data(., "xi_val")
    mata: n = rows(p)
    mata: G = 0
    mata: for (i=1; i<=n; i++) {
        for (j=1; j<=n; j++) {
            G = G + p[i] * p[j] * abs(x[i] - x[j])
        }
    }
    mata: mu = sum(p :* x)
    mata: G = G / (2 * mu)
    mata: st_numscalar("gini_mata", G)
    mata: st_numscalar("mu_mata", mu)
    
    local gini_educ = scalar(gini_mata)
    local mu = scalar(mu_mata)
    
    * Calcular también estadísticas adicionales
    qui sum xi_val [aw=peso]
    local min = r(min)
    local max = r(max)
    local range = `max' - `min'
    
    restore
    
    * Mostrar resultados
    if "`noprint'" != "noprint" {
        di _n as text "{title:Educational Gini Coefficient (Thomas, Wang & Fan, 2001)}"
        di as text "{hline 60}"
        di as text "Variable:       " as result "`varlist'"
        di as text "Type:           " as result "Discrete (Educational)"
        di as text "Level variable: " as result "`levelvar'"
        di as text "Xi variable:    " as result "`xivar'"
        di as text "Number of levels: " as result `n_levels'
        
        if !`unweighted' {
            di as text "Sum of weights:   " as result %12.2f `total_peso'
        }
        
        di as text "Weighted mean (μ): " as result %12.4f `mu'
        di as text "Range (max-min):   " as result %12.4f `range'
        di as text "Gini coefficient:  " as result %12.4f `gini_educ'
        di as text "{hline 60}"
        
        * Interpretación específica para educación
        di _n as text "Educational inequality interpretation:"
        if `gini_educ' < 0.15 {
            di as text "  Level: " as green "VERY LOW inequality"
            di as text "  Interpretation: High educational equality"
        }
        else if `gini_educ' < 0.25 {
            di as text "  Level: " as green "LOW inequality"
            di as text "  Interpretation: Moderate educational equality"
        }
        else if `gini_educ' < 0.35 {
            di as text "  Level: " as yellow "MODERATE inequality"
            di as text "  Interpretation: Some educational disparities"
        }
        else if `gini_educ' < 0.45 {
            di as text "  Level: " as red "HIGH inequality"
            di as text "  Interpretation: Significant educational gaps"
        }
        else {
            di as text "  Level: " as red "VERY HIGH inequality"
            di as text "  Interpretation: Severe educational disparities"
        }
    }
    
    * Devolver resultados
    return scalar gini = `gini_educ'
    return scalar mean = `mu'
    return scalar N = `total_peso'
    return scalar sum_w = `total_peso'
    return scalar niveles = `n_levels'
    return scalar min = `min'
    return scalar max = `max'
    return scalar range = `range'
    return local var "`varlist'"
    return local method "Thomas, Wang & Fan (2001)"
    return local type "discrete"
end

program define ginitwfsetup
    version 14
    syntax [if] [in]
    
    marksample touse
    
    di _n as text "{title:Setting up variables for Educational Gini Analysis}"
    di as text "Based on Thomas, Wang & Fan (2001) methodology"
    di as text "{hline 60}"
    
    * Verificar variable p10a (ENAHO)
    cap confirm variable p10a
    if _rc {
        di as yellow "Note: Variable p10a not found. Creating generic educational variables."
        
        * Crear variable de años de educación simulada
        if "`if'`in'" != "" {
            qui count if `touse'
            if r(N) > 0 {
                qui gen anios_educ = floor(runiform()*19) if `touse'
            }
            else {
                qui gen anios_educ = floor(runiform()*19)
            }
        }
        else {
            qui gen anios_educ = floor(runiform()*19)
        }
        
        di as green "✓ Created variable: anios_educ (simulated years of education)"
    }
    else {
        * Crear años de educación desde p10a (ENAHO)
        gen anios_educ = .
        
        replace anios_educ = 0 if inlist(p10a, 1, 2)    // Ninguno + Centro alfabetización
        replace anios_educ = 3 if p10a == 3              // Primaria (incompleta)
        replace anios_educ = 6 if p10a == 4              // Educación Básica (primaria completa)
        replace anios_educ = 9 if p10a == 5              // Secundaria (incompleta)  
        replace anios_educ = 11 if p10a == 6             // Educación Media (secundaria completa)
        replace anios_educ = 14 if p10a == 7             // Superior no universitario
        replace anios_educ = 16 if p10a == 8             // Superior Universitario
        replace anios_educ = 18 if p10a == 9             // Post-grado
        
        di as green "✓ Created variable: anios_educ from p10a"
    }
    
    * Crear niveles educativos (8 niveles según Thomas et al.)
    gen nivel_educ = .
    gen xi = .
    
    * Asignar niveles según rangos de años de educación
    replace nivel_educ = 1 if anios_educ == 0                    // Sin nivel
    replace xi = 0 if nivel_educ == 1
    
    replace nivel_educ = 2 if anios_educ >= 1 & anios_educ <= 5  // Primaria incompleta
    replace xi = 2.72 if nivel_educ == 2  // Promedio histórico
    
    replace nivel_educ = 3 if anios_educ == 6                    // Primaria completa
    replace xi = 6 if nivel_educ == 3
    
    replace nivel_educ = 4 if anios_educ >= 7 & anios_educ <= 10 // Secundaria incompleta
    replace xi = 8.48 if nivel_educ == 4  // Promedio histórico
    
    replace nivel_educ = 5 if anios_educ == 11                   // Secundaria completa
    replace xi = 11 if nivel_educ == 5
    
    replace nivel_educ = 6 if anios_educ >= 12 & anios_educ <= 15 // Superior incompleta
    replace xi = 13.54 if nivel_educ == 6  // Promedio histórico
    
    replace nivel_educ = 7 if anios_educ >= 16 & anios_educ <= 17 // Superior completa
    replace xi = 16.07 if nivel_educ == 7  // Promedio histórico
    
    replace nivel_educ = 8 if anios_educ >= 18                   // Postgrado
    replace xi = 18 if nivel_educ == 8
    
    * Etiquetar variables
    label variable anios_educ "Years of education"
    label variable nivel_educ "Educational level (1-8)"
    label variable xi "Average years by level (Thomas et al.)"
    
    label define niveles 1 "No education" 2 "Primary incomplete" 3 "Primary complete" ///
                        4 "Secondary incomplete" 5 "Secondary complete" ///
                        6 "Higher incomplete" 7 "Higher complete" 8 "Postgraduate"
    label values nivel_educ niveles
    
    * Estadísticas descriptivas
    qui count if !missing(anios_educ)
    local n = r(N)
    
    qui sum anios_educ
    local mean_educ = r(mean)
    local sd_educ = r(sd)
    
    qui tab nivel_educ
    local n_levels = r(r)
    
    di as green "✓ Created variable: nivel_educ (educational level 1-8)"
    di as green "✓ Created variable: xi (average years by level)"
    di _n
    di as text "Descriptive statistics:"
    di as text "  Observations with education data: " as result `n'
    di as text "  Mean years of education: " as result %6.2f `mean_educ'
    di as text "  Std. Dev. of education: " as result %6.2f `sd_educ'
    di as text "  Number of educational levels: " as result `n_levels'
    di _n
    di as text "To calculate Educational Gini, use:"
    di as result "  ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)"
    di _n
    di as text "For population aged 25+ (completed education):"
    di as result "  ginitwf anios_educ if edad >= 25, type(discrete) levels(nivel_educ) xivar(xi)"
end

program define ginitwfeduc
    version 14
    syntax [if] [in] [aweight fweight pweight iweight/] ///
        [, BY(varname) AGE(integer 25) SAVing(string) REPLACE]
    
    * Verificar variables necesarias
    cap confirm variable anios_educ nivel_educ xi
    if _rc {
        di as error "Educational variables not found. Run ginitwfsetup first."
        exit 111
    }
    
    * Filtrar por edad (por defecto 25+)
    if "`if'`in'" != "" {
        local filtro `if' `in' & edad >= `age'
    }
    else {
        local filtro if edad >= `age'
    }
    
    di _n as text "{title:Educational Gini Analysis (Population aged `age'+)}"
    di as text "Based on Thomas, Wang & Fan (2001)"
    di as text "{hline 60}"
    
    if "`by'" != "" {
        ginitwf anios_educ `filtro' `exp', by(`by') type(discrete) ///
            levels(nivel_educ) xivar(xi) saving(`saving') `replace'
    }
    else {
        ginitwf anios_educ `filtro' `exp', type(discrete) ///
            levels(nivel_educ) xivar(xi) saving(`saving') `replace'
    }
end

program define ginitwfresumen
    version 14
    syntax [, SAVe(string) REPLACE EXPort(string) CLEAR]
    
    * Verificar que hay resultados
    if "`r(type)'" == "" {
        di as error "No results from ginitwf. Run ginitwf first."
        exit 301
    }
    
    di _n as text "{title:Summary of Gini Analysis}"
    di as text "{hline 60}"
    di as text "Method:          " as result "`r(method)'"
    di as text "Type:            " as result "`r(type)'"
    di as text "Variable:        " as result "`r(var)'"
    di as text "Observations:    " as result r(N)
    
    if r(sum_w) != . & r(sum_w) != r(N) {
        di as text "Sum of weights:  " as result %12.2f r(sum_w)
    }
    
    di as text "Mean (μ):        " as result %12.4f r(mean)
    di as text "Gini coefficient:" as result %12.4f r(gini)
    
    if "`r(type)'" == "discrete" {
        di as text "Levels:          " as result r(niveles)
        if r(min) != . & r(max) != . {
            di as text "Range (min-max): " as result r(min) " - " r(max)
        }
    }
    else if "`r(type)'" == "continuous" {
        if r(sd) != . {
            di as text "Std. Deviation:  " as result %12.4f r(sd)
        }
    }
    
    di as text "{hline 60}"
    
    * Interpretación
    di _n as text "Interpretation of Gini coefficient:"
    
    if "`r(type)'" == "discrete" {
        * Escala para Gini educativo
        if r(gini) < 0.15 {
            di as text "  Educational inequality: " as green "VERY LOW"
            di as text "  Interpretation: High educational equality in the population"
        }
        else if r(gini) < 0.25 {
            di as text "  Educational inequality: " as green "LOW"
            di as text "  Interpretation: Moderate educational equality"
        }
        else if r(gini) < 0.35 {
            di as text "  Educational inequality: " as yellow "MODERATE"
            di as text "  Interpretation: Noticeable educational disparities"
        }
        else if r(gini) < 0.45 {
            di as text "  Educational inequality: " as red "HIGH"
            di as text "  Interpretation: Significant educational gaps"
        }
        else {
            di as text "  Educational inequality: " as red "VERY HIGH"
            di as text "  Interpretation: Severe educational inequality"
        }
    }
    else {
        * Escala para Gini general
        if r(gini) < 0.2 {
            di as text "  Inequality level: " as green "LOW"
            di as text "  Interpretation: Relatively equal distribution"
        }
        else if r(gini) < 0.4 {
            di as text "  Inequality level: " as yellow "MODERATE"
            di as text "  Interpretation: Acceptable but could improve"
        }
        else if r(gini) < 0.6 {
            di as text "  Inequality level: " as red "HIGH"
            di as text "  Interpretation: Significant inequality"
        }
        else {
            di as text "  Inequality level: " as red "VERY HIGH"
            di as text "  Interpretation: Extreme inequality"
        }
    }
    
    * Guardar resultados si se solicita
    if "`save'" != "" {
        preserve
        clear
        
        * Crear dataset con resultados
        set obs 1
        gen variable = "`r(var)'"
        gen method = "`r(method)'"
        gen type = "`r(type)'"
        gen N = r(N)
        gen sum_w = r(sum_w)
        gen mean = r(mean)
        gen gini = r(gini)
        
        if "`r(type)'" == "discrete" {
            gen niveles = r(niveles)
            gen min = r(min)
            gen max = r(max)
            gen range = r(max) - r(min)
        }
        else if "`r(type)'" == "continuous" {
            gen sd = r(sd)
        }
        
        gen fecha = date(c(current_date), "DMY")
        format fecha %td
        
        save "`save'", `replace'
        di as green _n "Results saved to: `save'"
        
        if "`export'" != "" {
            if inlist("`export'", "csv", "excel", "dta") {
                if "`export'" == "csv" {
                    export delimited using "`save'.csv", replace
                    di as green "Exported to CSV: `save'.csv"
                }
                else if "`export'" == "excel" {
                    export excel using "`save'.xlsx", firstrow(variables) replace
                    di as green "Exported to Excel: `save'.xlsx"
                }
                else if "`export'" == "dta" {
                    save "`save'.dta", replace
                    di as green "Exported to Stata: `save'.dta"
                }
            }
        }
        
        if "`clear'" == "clear" {
            restore, not
        }
        else {
            restore
        }
    }
end

program define ginitwfhelp
    version 14
    di _n
    di as text "{title:GINITWF - Gini Coefficient Calculator for Stata}"
    di as text "{hline 70}"
    di _n
    di as text "Version: 2.0.0 (30 March 2025)"
    di as text "Author: Washington Quintero"
    di as text "Institution: Universidad de Guayaquil"
    di as text "Repository: {browse https://github.com/washingtonquintero/ginitwf}"
    di _n
    di as text "{hline 70}"
    di _n
    
    di as text "{bf:MAIN COMMANDS:}"
    di _n
    di as text "  {bf:ginitwf} varname [if] [in] [weight] [, options]"
    di as text "     Calculate Gini coefficient for continuous or discrete variables"
    di _n
    di as text "  {bf:ginitwfsetup} [if] [in]"
    di as text "     Setup educational variables for Gini analysis (creates anios_educ, nivel_educ, xi)"
    di _n
    di as text "  {bf:ginitwfeduc} [if] [in] [weight] [, by(varname) age(#) saving()]"
    di as text "     Calculate Educational Gini for population aged 25+ (or specified age)"
    di _n
    di as text "  {bf:ginitwfresumen} [, save(filename) replace export(format) clear]"
    di as text "     Show detailed summary and optionally save results"
    di _n
    di as text "  {bf:ginitwfhelp}"
    di as text "     Show this help"
    di _n
    
    di as text "{bf:MAIN OPTIONS for ginitwf:}"
    di _n
    di as text "  {bf:type(continuous|discrete)}" _col(30) "Type of variable"
    di as text "  {bf:levels(varname)}" _col(30) "Level variable (for discrete type)"
    di as text "  {bf:xivar(varname)}" _col(30) "Xi variable with average years (for discrete)"
    di as text "  {bf:by(varname)}" _col(30) "Calculate Gini by groups"
    di as text "  {bf:educational}" _col(30) "Shortcut for type(discrete)"
    di as text "  {bf:saving(filename)}" _col(30) "Save results to file"
    di as text "  {bf:replace}" _col(30) "Replace existing file"
    di as text "  {bf:noprint}" _col(30) "Suppress output"
    di _n
    
    di as text "{bf:WEIGHT TYPES supported:}"
    di as text "  aweight, fweight, pweight, iweight"
    di _n
    
    di as text "{bf:EXAMPLES:}"
    di _n
    di as text "  1. Gini for continuous variable:"
    di as result "     . ginitwf income, type(continuous)"
    di as result "     . ginitwf income [aw=weight], by(region)"
    di _n
    di as text "  2. Educational Gini:"
    di as result "     . ginitwfsetup"
    di as result "     . ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)"
    di as result "     . ginitwfeduc, by(area) saving(results.dta)"
    di _n
    di as text "  3. With weights and saving results:"
    di as result "     . ginitwf gasto_educ [aw=peso], by(quintil) saving(gini_quintil.dta)"
    di as result "     . ginitwfresumen, save(summary.xlsx) export(excel)"
    di _n
    
    di as text "{bf:METHODOLOGICAL REFERENCES:}"
    di _n
    di as text "  1. Deaton, A. (1997). {it:The Analysis of Household Surveys:}"
    di as text "     {it:A Microeconometric Approach to Development Policy.}"
    di as text "     Johns Hopkins University Press."
    di _n
    di as text "  2. Thomas, V., Wang, Y., & Fan, X. (2001). {it:Measuring Education Inequality:}"
    di as text "     {it:Gini Coefficients of Education.} World Bank Policy Research"
    di as text "     Working Paper No. 2525."
    di _n
    di as text "  3. Cuenca, R., & Urrutia, C. E. (2019). {it:Explorando las brechas}"
    di as text "     {it:de desigualdad educativa en el Perú.} Revista Mexicana de"
    di as text "     Investigación Educativa, 24(81), 431-461."
    di _n
    
    di as text "{bf:FOR MORE HELP:}"
    di as text "  Online documentation: {browse https://github.com/washingtonquintero/ginitwf}"
    di as text "  Course materials: {browse https://gptonline.ai/}"
    di as text "  Email: washington.quintero@ug.edu.ec"
    di _n
    di as text "{hline 70}"
end
