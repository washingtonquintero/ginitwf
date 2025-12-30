
*! version 3.1.0 2025-03-30
*! Ginitwf: Gini coefficients with improved error handling
*! Author: Washington Quintero
*! Repository: https://github.com/washingtonquintero/ginitwf

program define ginitwf, rclass
    version 14
    syntax varname [if] [in] [aweight fweight pweight iweight/] ///
        [, BY(varname) TYPE(string) LEVels(varname) XIvar(varname) ///
        EDUcational SAVing(string) REPLace noPRINT]
    
    * Verificar que la variable principal existe
    capture confirm variable `varlist'
    if _rc {
        di as error "La variable `varlist' no existe en el dataset"
        exit 111
    }
    
    marksample touse
    markout `touse' `by'
    
    * Verificar variable de peso si se especificó
    if "`weight'" != "" {
        local peso_exp = subinstr(`"`exp'"', "=", "", 1)
        
        * Verificar que la variable de peso existe
        capture confirm variable `peso_exp'
        if _rc {
            di as error "La variable de peso '`peso_exp'' no existe en el dataset"
            di as text "Sugerencia: Cree la variable primero, por ejemplo:"
            di as result "  gen `peso_exp' = 1"
            exit 111
        }
        
        * Verificar que no tenga valores missing o cero
        qui count if `touse' & missing(`peso_exp')
        if r(N) > 0 {
            di as yellow "Advertencia: La variable de peso '`peso_exp'' tiene " ///
                r(N) " valores missing en las observaciones usadas"
        }
        
        qui count if `touse' & `peso_exp' <= 0
        if r(N) > 0 {
            di as yellow "Advertencia: La variable de peso '`peso_exp'' tiene " ///
                r(N) " valores ≤ 0 en las observaciones usadas"
        }
    }
    
    * Mensaje informativo mejorado
    if ("`by'" != "" | "`weight'" != "") & "`noprint'" == "" {
        di as text _n "Nota: Usando opciones avanzadas"
        if "`by'" != "" {
            di as text "  - by(`by')"
        }
        if "`weight'" != "" {
            di as text "  - `weight'(`peso_exp')"
        }
    }
    
    * Determinar tipo de análisis
    if "`educational'" != "" {
        local type "discrete"
    }
    
    * Opción 1: CON by() - Análisis por grupos
    if "`by'" != "" {
        * Verificar que la variable by existe
        capture confirm variable `by'
        if _rc {
            di as error "La variable de agrupación '`by'' no existe en el dataset"
            exit 111
        }
        
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
