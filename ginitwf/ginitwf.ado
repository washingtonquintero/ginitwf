*! version 1.1.0 2025-12-29
*! GINITWF — Gini for continuous & discrete variables
*! Washington Quintero

program define ginitwf, rclass
    version 14
    syntax varname [if] [in], ///
        [ TYPE(string) LEVELS(varname) XIVAR(varname) EDUCATIONAL ///
          BY(varname) WEIGHT(varname) ]

    marksample touse

    /* --------------------------------------------------
       Preparar grupo y peso
    -------------------------------------------------- */
    tempvar g w
    gen `g' = cond("`by'"=="", 1, `by') if `touse'
    gen double `w' = cond("`weight'"=="", 1, `weight') if `touse'

    /* --------------------------------------------------
       Inferencia automática de tipo
    -------------------------------------------------- */
    if "`educational'" != "" local type "discrete"

    if "`type'" == "" {
        quietly tab `varlist' if `touse'
        local unique = r(r)
        if `unique' <= 12 & "`levels'" != "" & "`xivar'" != "" {
            local type "discrete"
            di as text "Nota: Tipo inferido como DISCRETE (valores únicos: `unique')"
        }
        else {
            local type "continuous"
            di as text "Nota: Tipo inferido como CONTINUOUS (valores únicos: `unique')"
        }
    }

    /* --------------------------------------------------
       Ejecutar por grupo
    -------------------------------------------------- */
    levelsof `g' if `touse', local(grps)

    foreach k of local grps {

        preserve
        keep if `g'==`k' & `touse'
        qui replace `varlist' = `varlist' * `w'

        if "`type'"=="continuous" {
            _gini_cont `varlist'
        }
        else {
            if "`levels'"=="" | "`xivar'"=="" {
                di as err "levels() y xivar() requeridos para tipo DISCRETE"
                exit 198
            }
            _gini_disc `varlist', levels(`levels') xivar(`xivar')
        }

        restore
    }

end

/* ================= CONTINUOUS ================= */

program define _gini_cont, rclass
    version 14
    syntax varname

    qui sum `varlist', meanonly
    local mu = r(mean)
    local n  = r(N)

    sort `varlist'
    gen long i = _n
    gen double s = sum(`varlist')
    gen double g = (2*i-`n'-1)*`varlist'
    qui sum g
    local G = r(sum)/( `n'*( `n'-1 )*`mu' )

    di as text "Gini (Deaton 1997): " as res %9.4f `G'
    return scalar gini = `G'
end

/* ================= DISCRETE ================= */

program define _gini_disc, rclass
    version 14
    syntax varname, LEVELS(varname) XIVAR(varname)

    collapse (count) n=`varlist' (mean) x=`xivar', by(`levels')
    gen p = n/sum(n)
    gen px = p*x
    qui sum px
    local mu = r(sum)

    mata:
        p = st_data(., "p")
        x = st_data(., "x")
        n = rows(p)
        G = 0
        for(i=1;i<=n;i++) for(j=1;j<=n;j++) G += p[i]*p[j]*abs(x[i]-x[j])
        G = G/(2*sum(p:*x))
        st_numscalar("GG",G)
    end

    di as text "Gini Educativo (TWF 2001): " as res %9.4f scalar(GG)
    return scalar gini = scalar(GG)
end

