{smcl}
{* *! version 3.0.0 30-Mar-2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "ginitwf##syntax"}{...}
{viewerjumpto "Description" "ginitwf##description"}{...}
{viewerjumpto "Options" "ginitwf##options"}{...}
{viewerjumpto "Examples" "ginitwf##examples"}{...}
{viewerjumpto "Saved results" "ginitwf##saved_results"}{...}
{viewerjumpto "References" "ginitwf##references"}{...}
{title:Title}

{phang}
{bf:ginitwf} {hline 2} Calcula coeficientes de Gini con/sin opciones by() y weight()

{marker syntax}{...}
{title:Syntax}

{phang}
{bf:Versión básica (sin by/weight):}

{p 8 17 2}
{cmdab:ginitwf} {varname} [{cmd:if}] [{cmd:in}] [{cmd:,} {opt type(continuous|discrete)} {opt levels(varname)} {opt xivar(varname)}]

{phang}
{bf:Versión avanzada (con by/weight):}

{p 8 17 2}
{cmdab:ginitwf} {varname} [{cmd:if}] [{cmd:in}] [{cmd:aweight} {cmd:fweight} {cmd:pweight} {cmd:iweight}] [{cmd:,} {opt by(varname)} {opt type(continuous|discrete)} {opt levels(varname)} {opt xivar(varname)} {opt saving(filename)} {opt replace}]

{phang}
{bf:Comandos auxiliares:}

{p 8 17 2}
{cmdab:ginitwfsetup}

{p 8 17 2}
{cmdab:ginitwfeduc} [{cmd:if}] [{cmd:in}] [{cmd:aweight} {cmd:fweight}] [{cmd:,} {opt by(varname)} {opt age(#)}]

{p 8 17 2}
{cmdab:ginitwfresumen} [{cmd:,} {opt save(filename)} {opt replace}]

{p 8 17 2}
{cmdab:ginitwfhelp}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt type}}tipo de variable: continuous o discrete{p_end}
{synopt:{opt levels}}para tipo discrete: variable de niveles{p_end}
{synopt:{opt xivar}}para tipo discrete: variable con valores xi{p_end}
{synopt:{opt by}}calcular por grupos{p_end}
{synopt:{opt saving}}guardar resultados en archivo{p_end}
{synopt:{opt replace}}reemplazar archivo existente{p_end}

{syntab:Weight}
{synopt:{opt aweight}}pesos analíticos{p_end}
{synopt:{opt fweight}}pesos de frecuencia{p_end}
{synopt:{opt pweight}}pesos de probabilidad{p_end}
{synopt:{opt iweight}}pesos de importancia{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ginitwf} es un paquete Stata para calcular coeficientes de Gini que funciona en dos modos:

{pstd}
{bf:1. Modo básico:} Sin opciones {opt by()} ni {opt weight}. Compatible con versiones anteriores.
Calcula el coeficiente de Gini usando las fórmulas de Deaton (1997) para variables continuas
y Thomas, Wang & Fan (2001) para variables discretas (Gini Educativo).

{pstd}
{bf:2. Modo avanzado:} Con opciones {opt by()} y/o {opt weight}. Permite análisis por subgrupos
y uso de pesos muestrales. Mantiene retrocompatibilidad con el modo básico.

{pstd}
El paquete incluye comandos auxiliares para preparar datos educativos ({cmd:ginitwfsetup}),
calcular Gini educativo de forma simplificada ({cmd:ginitwfeduc}), mostrar resúmenes
({cmd:ginitwfresumen}) y obtener ayuda ({cmd:ginitwfhelp}).

{marker options}{...}
{title:Options}

{dlgtab:Main}
{phang}
{opt type(continuous|discrete)} especifica el tipo de variable. Si no se especifica,
el programa intenta inferirlo automáticamente basado en el número de valores únicos.

{phang}
{opt levels(varname)} especifica la variable que contiene los niveles educativos
(1-8 según Thomas et al.). Requerido para {opt type(discrete)}.

{phang}
{opt xivar(varname)} especifica la variable que contiene los años de educación
promedio para cada nivel. Requerido para {opt type(discrete)}.

{phang}
{opt by(varname)} calcula el coeficiente de Gini para cada grupo definido por
{it:varname}. Los resultados se presentan en una tabla comparativa.

{phang}
{opt saving(filename)} guarda los resultados en un archivo Stata (.dta).

{phang}
{opt replace} permite reemplazar el archivo si ya existe.

{dlgtab:Weight}
{phang}
Los pesos son opcionales y se especifican antes de las opciones:

{pmore}
{cmd:aweight} (pesos analíticos) - Para datos de encuestas

{pmore}
{cmd:fweight} (pesos de frecuencia) - Para datos expandidos

{pmore}
{cmd:pweight} (pesos de probabilidad) - Para diseños muestrales complejos

{pmore}
{cmd:iweight} (pesos de importancia) - Para ponderaciones generales

{marker examples}{...}
{title:Examples}

{phang}
{bf:Ejemplo 1: Modo básico (sin by/weight)}

{pmore}{cmd:. sysuse auto, clear}{p_end}
{pmore}{cmd:. ginitwf price, type(continuous)}{p_end}

{pmore}{cmd:. * Para datos educativos:}{p_end}
{pmore}{cmd:. ginitwfsetup}{p_end}
{pmore}{cmd:. ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)}{p_end}

{phang}
{bf:Ejemplo 2: Modo avanzado (con by y weight)}

{pmore}{cmd:. gen peso = rep78}{p_end}
{pmore}{cmd:. replace peso = 1 if missing(peso)}{p_end}
{pmore}{cmd:. ginitwf price [aweight=peso], by(foreign)}{p_end}

{pmore}{cmd:. * Gini educativo por región con pesos:}{p_end}
{pmore}{cmd:. ginitwf anios_educ [aweight=peso_muestral], by(region) type(discrete) levels(nivel_educ) xivar(xi)}{p_end}

{phang}
{bf:Ejemplo 3: Comandos auxiliares}

{pmore}{cmd:. ginitwfeduc if edad >= 25, by(area) saving(gini_area.dta)}{p_end}
{pmore}{cmd:. ginitwfresumen, save(resumen.xlsx) replace}{p_end}
{pmore}{cmd:. ginitwfhelp}{p_end}

{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:ginitwf} (modo básico) guarda en {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(gini)}}coeficiente de Gini{p_end}
{synopt:{cmd:r(mean)}}media de la variable{p_end}
{synopt:{cmd:r(N)}}número de observaciones{p_end}
{synopt:{cmd:r(min)}}valor mínimo{p_end}
{synopt:{cmd:r(max)}}valor máximo{p_end}
{synopt:{cmd:r(niveles)}}número de niveles (solo discrete){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}tipo de análisis (continuous/discrete){p_end}
{synopt:{cmd:r(method)}}metodología utilizada{p_end}
{synopt:{cmd:r(var)}}nombre de la variable{p_end}

{pstd}
{cmd:ginitwf} (modo con {cmd:by()}) guarda adicionalmente:

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results_by)}}matriz con resultados por grupo{p_end}
{synopt:{cmd:r(n_groups)}}número de grupos{p_end}
{synopt:{cmd:r(by_var)}}nombre de la variable de agrupación{p_end}

{marker references}{...}
{title:References}

{pstd}
Deaton, A. (1997). {it:The Analysis of Household Surveys: A Microeconometric Approach to Development Policy.}
Baltimore: Johns Hopkins University Press.

{pstd}
Thomas, V., Wang, Y., & Fan, X. (2001). {it:Measuring Education Inequality: Gini Coefficients of Education.}
World Bank Policy Research Working Paper No. 2525.

{pstd}
Cuenca, R., & Urrutia, C. E. (2019). {it:Explorando las brechas de desigualdad educativa en el Perú.}
Revista Mexicana de Investigación Educativa, 24(81), 431-461.

{title:Author}

{pstd}
Washington Quintero{p_end}
{pstd}
Universidad de Guayaquil{p_end}
{pstd}
Email: washington.quintero@ug.edu.ec{p_end}
{pstd}
GitHub: {browse "https://github.com/washingtonquintero/ginitwf"}{p_end}

{title:Also see}

{pstd}
Online: {help inequality} (if installed){p_end}
{pstd}
Related: {help ineqdeco} (if installed){p_end}
{pstd}
Website: {browse "https://gptonline.ai/"}{p_end}
