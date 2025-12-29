*! version 1.0.0 2025-03-30
*! Calcula coeficiente de Gini para variables continuas y Gini educativo para discretas
*! Autores: Basado en Deaton (1997) y Thomas, Wang & Fan (2001)
*! Repositorio: https://github.com/washingtonquintero/ginitwf

program define gincontinuous, rclass
    version 14
    syntax varname [if] [in]
    marksample touse
    
    * Verificar que la variable sea numérica
    confirm numeric variable `varlist'
    
    * Calcular estadísticas básicas
    qui sum `varlist' if `touse', meanonly
    local mu = r(mean)
    local n = r(N)
    
    if `n' == 0 {
        di as error "No hay observaciones válidas"
        exit 2000
    }
    
    if `mu' == 0 {
        di as error "La media es cero, no se puede calcular Gini"
        exit 198
    }
    
    * Ordenar datos para cálculo eficiente
    preserve
    qui keep if `touse'
    keep `varlist'
    sort `varlist'
    
    * Calcular usando fórmula eficiente: G = (2/(n^2*mu)) * sum(i*x_i) - (n+1)/n
    gen long orden = _n
    gen double prod = orden * `varlist'
    qui sum prod
    local sum_prod = r(sum)
    
    * Fórmula alternativa más estable
    * G = (1/(n*(n-1)*mu)) * sum_{i>j} |x_i - x_j|
    * Usamos el método de Brown (1994) para mayor eficiencia
    gen double acu_sum = sum(`varlist')
    local total_sum = acu_sum[_N]
    
    * Calcular numerador
    gen double term = (2*orden - `n' - 1) * `varlist'
    qui sum term
    local numerador = r(sum)
    
    * Calcular Gini
    local gini = `numerador' / (`n' * (`n' - 1) * `mu')
    
    restore
    
    * Resultados
    di _n as text "Coeficiente de Gini (Deaton, 1997)"
    di as text "Variable: " as result "`varlist'"
    di as text "Observaciones: " as result `n'
    di as text "Media (μ): " as result %9.4f `mu'
    di as text "Coeficiente de Gini: " as result %9.4f `gini'
    
    return scalar gini = `gini'
    return scalar mean = `mu'
    return scalar N = `n'
    return local var "`varlist'"
    return local method "Deaton (1997)"
end

program define ginidiscrete, rclass
    version 14
    syntax varname [if] [in], Levelvar(varname) Xivar(varname)
    marksample touse
    
    * Verificar variables
    confirm numeric variable `varlist'
    confirm numeric variable `levelvar'
    confirm numeric variable `xivar'
    
    preserve
    qui keep if `touse'
    keep `varlist' `levelvar' `xivar'
    
    * Verificar que xi sea constante por nivel
    bysort `levelvar': egen double xi_check = sd(`xivar')
    qui sum xi_check
    if r(max) > 0.0001 {
        di as error "Error: xi no es constante por nivel educativo"
        exit 198
    }
    drop xi_check
    
    * Colapsar por nivel para obtener proporciones
    collapse (count) n_obs = `varlist' (mean) xi_val = `xivar', by(`levelvar')
    
    * Ordenar por xi_val (ascendente)
    sort xi_val
    
    * Calcular total de observaciones
    qui sum n_obs
    local N_total = r(sum)
    
    * Calcular proporciones
    gen double p_i = n_obs / `N_total'
    
    * Calcular promedio ponderado (μ)
    gen double p_x = p_i * xi_val
    qui sum p_x
    local mu = r(sum)
    
    * Número de niveles
    local m = _N
    
    * Calcular doble sumatoria: ΣΣ p_i * p_j * |x_i - x_j|
    gen double sumatoria = 0
    
    forvalues i = 1/`m' {
        forvalues j = 1/`m' {
            if `i' != `j' {
                local dif = abs(xi_val[`i'] - xi_val[`j'])
                replace sumatoria = sumatoria + p_i[`i'] * p_i[`j'] * `dif'
            }
        }
    }
    
    * Calcular Gini educativo
    qui sum sumatoria
    local suma_total = r(max)  // Todas las observaciones tienen el mismo valor
    
    local gini_educ = (1/(2*`mu')) * `suma_total'
    
    * Calcular también usando fórmula matricial (más eficiente)
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
    
    local gini_educ = scalar(gini_mata)
    
    restore
    
    * Mostrar resultados
    di _n as text "Coeficiente de Gini Educativo (Thomas, Wang & Fan, 2001)"
    di as text "Variable de años: " as result "`varlist'"
    di as text "Variable de nivel: " as result "`levelvar'"
    di as text "Variable xi: " as result "`xivar'"
    di as text "Niveles educativos: " as result `m'
    di as text "Observaciones: " as result `N_total'
    di as text "Media ponderada (μ): " as result %9.4f `mu'
    di as text "Gini Educativo: " as result %9.4f `gini_educ'
    
    return scalar gini = `gini_educ'
    return scalar mean = `mu'
    return scalar N = `N_total'
    return scalar niveles = `m'
    return local var "`varlist'"
    return local method "Thomas, Wang & Fan (2001)"
end

program define ginitwf, rclass
    version 14
    syntax varname [if] [in], [TYPE(string) LEVels(varname) XIvar(varname) EDUcational]
    
    marksample touse
    
    * Determinar tipo de análisis
    if "`educational'" != "" {
        local type "discrete"
    }
    
    if "`type'" == "" {
        * Intentar inferir tipo automáticamente
        qui tab `varlist' if `touse', matcell(freq)
        local unique_vals = r(r)
        
        if `unique_vals' <= 10 & "`levels'" != "" & "`xivar'" != "" {
            local type "discrete"
            di as text "Nota: Tipo inferido como DISCRETE (valores únicos: `unique_vals')"
        }
        else {
            local type "continuous"
            di as text "Nota: Tipo inferido como CONTINUOUS (valores únicos: `unique_vals')"
        }
    }
    
    if "`type'" == "continuous" {
        gincontinuous `varlist' if `touse'
        
        * Guardar todos los resultados
        return scalar gini = r(gini)
        return scalar mean = r(mean)
        return scalar N = r(N)
        return local var = r(var)
        return local method = r(method)
        return local type = "continuous"
    }
    else if "`type'" == "discrete" {
        if "`levels'" == "" | "`xivar'" == "" {
            di as error "Para tipo DISCRETE, debe especificar: levels() y xivar()"
            di as error "Ejemplo: ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)"
            exit 198
        }
        
        ginidiscrete `varlist' if `touse', levelvar(`levels') xivar(`xivar')
        
        * Guardar todos los resultados
        return scalar gini = r(gini)
        return scalar mean = r(mean)
        return scalar N = r(N)
        return scalar niveles = r(niveles)
        return local var = r(var)
        return local method = r(method)
        return local type = "discrete"
    }
    else {
        di as error "Tipo no reconocido. Use: continuous o discrete"
        exit 198
    }
    
    * Guardar resultados en matriz
    matrix GiniResult = (r(gini), r(mean), r(N))
    matrix colnames GiniResult = Gini Mean N
    matrix rownames GiniResult = `r(var)'
    
    return matrix results = GiniResult
end

program define ginitwfsetup
    version 14
    di as text _n "Configurando variables para Gini Educativo..."
    di as text "Este programa crea las variables necesarias para el cálculo del Gini Educativo"
    di as text "Basado en Thomas, Wang & Fan (2001)" _n
    
    * Crear variable de años de educación desde p10a (ENAHO)
    cap confirm variable p10a
    if _rc {
        di as error "Variable p10a no encontrada"
        exit 111
    }
    
    * Generar años de educación
    gen anios_educ = .
    replace anios_educ = 0 if inlist(p10a, 1, 2)    // Ninguno + Centro alfabetización
    replace anios_educ = 3 if p10a == 3              // Primaria (incompleta)
    replace anios_educ = 6 if p10a == 4              // Educación Básica (primaria completa)
    replace anios_educ = 9 if p10a == 5              // Secundaria (incompleta)  
    replace anios_educ = 11 if p10a == 6             // Educación Media (secundaria completa)
    replace anios_educ = 14 if p10a == 7             // Superior no universitario
    replace anios_educ = 16 if p10a == 8             // Superior Universitario
    replace anios_educ = 18 if p10a == 9             // Post-grado
    
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
    label variable anios_educ "Años de educación"
    label variable nivel_educ "Nivel educativo (1-8)"
    label variable xi "Años promedio por nivel (Thomas et al.)"
    
    label define niveles 1 "Sin nivel" 2 "Primaria inc." 3 "Primaria comp." ///
                        4 "Secundaria inc." 5 "Secundaria comp." ///
                        6 "Superior inc." 7 "Superior comp." 8 "Postgrado"
    label values nivel_educ niveles
    
    di as result "Variables creadas exitosamente:"
    di as result "  anios_educ: Años de educación"
    di as result "  nivel_educ: Niveles educativos (1-8)"
    di as result "  xi: Años promedio por nivel"
    di _n
    di as text "Para calcular Gini Educativo, use:"
    di as result "  ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)"
end

program define ginitwfeduc
    version 14
    syntax [if] [in]
    
    di as text _n "Calculando Gini Educativo para población que dejó de estudiar..."
    
    * Usar variables creadas por ginitwfsetup
    cap confirm variable nivel_educ xi
    if _rc {
        di as error "Primero ejecute: ginitwfsetup"
        exit 111
    }
    
    * Filtrar población que dejó de estudiar (mayores de 25 años)
    marksample touse
    local cond_edad "edad >= 25"
    
    * Aplicar filtros
    if "`if'`in'" != "" {
        local filtro `if' `in'
        ginitwf anios_educ `filtro' & `cond_edad', type(discrete) levels(nivel_educ) xivar(xi)
    }
    else {
        ginitwf anios_educ if `cond_edad', type(discrete) levels(nivel_educ) xivar(xi)
    }
end

program define ginitwfresumen
    version 14
    syntax, [SAVe(string) REPlace]
    
    * Verificar que hay resultados previos
    if "`r(type)'" == "" {
        di as error "No hay resultados previos. Ejecute ginitwf primero."
        exit 301
    }
    
    * Mostrar resumen detallado
    di _n as text "="*60
    di as text "RESUMEN DE RESULTADOS GINI"
    di as text "="*60
    di as text "Método: " as result "`r(method)'"
    di as text "Tipo: " as result "`r(type)'"
    di as text "Variable: " as result "`r(var)'"
    di as text "N observaciones: " as result r(N)
    di as text "Media (μ): " as result %9.4f r(mean)
    di as text "Coeficiente Gini: " as result %9.4f r(gini)
    
    if "`r(type)'" == "discrete" {
        di as text "Niveles educativos: " as result r(niveles)
    }
    
    * Interpretación
    di _n as text "Interpretación del coeficiente:"
    if r(gini) < 0.2 {
        di as text "  Nivel de desigualdad: " as result "BAJA desigualdad"
    }
    else if r(gini) < 0.4 {
        di as text "  Nivel de desigualdad: " as result "DESIGUALDAD MODERADA"
    }
    else if r(gini) < 0.6 {
        di as text "  Nivel de desigualdad: " as result "ALTA desigualdad"
    }
    else {
        di as text "  Nivel de desigualdad: " as result "MUY ALTA desigualdad"
    }
    
    * Guardar resultados si se solicita
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
        if "`r(type)'" == "discrete" {
            gen niveles = r(niveles)
        }
        
        save "`save'", `replace'
        restore
        
        di as text _n "Resultados guardados en: `save'"
    }
end

program define ginitwfhelp
    version 14
    di as text _n "PAQUETE GINITWF - CÁLCULO DE COEFICIENTES GINI"
    di as text "="*60
    di _n
    di as text "COMANDOS DISPONIBLES:"
    di _n
    di as text "  {bf:ginitwf} varname [if] [in], [type(continuous|discrete) levels() xivar()]"
    di as text "     Calcula coeficiente de Gini para variable continua o discreta"
    di _n
    di as text "  {bf:ginitwfsetup}"
    di as text "     Prepara variables para cálculo de Gini Educativo (crea nivel_educ, xi)"
    di _n
    di as text "  {bf:ginitwfeduc} [if] [in]"
    di as text "     Calcula Gini Educativo para población que dejó de estudiar (edad≥25)"
    di _n
    di as text "  {bf:ginitwfresumen} [, save(archivo) replace]"
    di as text "     Muestra resumen detallado y opcionalmente guarda resultados"
    di _n
    di as text "  {bf:ginitwfhelp}"
    di as text "     Muestra esta ayuda"
    di _n
    di as text "EJEMPLOS:"
    di as text "  Para Gini de gasto educativo (continuo):"
    di as result "    . ginitwf gasto_educ, type(continuous)"
    di _n
    di as text "  Para Gini Educativo (discreto):"
    di as result "    . ginitwfsetup"
    di as result "    . ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)"
    di _n
    di as text "  Versión simplificada:"
    di as result "    . ginitwfeduc"
    di _n
    di as text "METODOLOGÍA:"
    di as text "  - Continuo: Deaton, A. (1997). The Analysis of Household Surveys"
    di as text "  - Discreto: Thomas, V., Wang, Y., & Fan, X. (2001). World Bank"
    di _n
    di as text "REPOSITORIO: https://github.com/washingtonquintero/ginitwf"
    di as text "MÁS AYUDA: https://gptonline.ai/"
end
