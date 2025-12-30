{smcl}
{* *! version 3.0.3 30mar2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "ginitwf##syntax"}{...}
{viewerjumpto "Description" "ginitwf##description"}{...}
{viewerjumpto "Options" "ginitwf##options"}{...}
{viewerjumpto "Examples" "ginitwf##examples"}{...}
{viewerjumpto "Saved results" "ginitwf##saved_results"}{...}
{viewerjumpto "Methods and formulas" "ginitwf##methods"}{...}
{viewerjumpto "References" "ginitwf##references"}{...}
{title:Title}

{phang}
{bf:ginitwf} {hline 2} Calcula coeficientes de Gini para variables continuas (Deaton, 1997) y Gini Educativo para variables discretas (Thomas, Wang y Fan, 2001)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:ginitwf} {varname} [{cmd:if}] [{cmd:in}] [{cmd:aweight} {cmd:fweight} {cmd:pweight} {cmd:iweight}] [{cmd:,} {opt type(continuous|discrete)} {opt by(varname)} {opt levels(varname)} {opt xivar(varname)} {opt educational} {opt saving(filename)} {opt replace} {opt noprint}]

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
{synopt:{opt type}}especifica el tipo de variable: continuous o discrete{p_end}
{synopt:{opt by}}calcula el coeficiente por grupos{p_end}
{synopt:{opt levels}}para tipo discrete: variable de niveles educativos{p_end}
{synopt:{opt xivar}}para tipo discrete: variable con los años promedio por nivel (xi){p_end}
{synopt:{opt educational}}atajo para tipo discrete{p_end}
{synopt:{opt saving}}guarda los resultados en un archivo{dta}{p_end}
{synopt:{opt replace}}reemplaza el archivo si ya existe{p_end}
{synopt:{opt noprint}}suprime la salida en pantalla{p_end}

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
{cmd:ginitwf} calcula el coeficiente de Gini para variables continuas (método de Deaton, 1997) y el Gini Educativo para variables discretas (método de Thomas, Wang y Fan, 2001). El paquete está diseñado para ser compatible con versiones anteriores, funcionando tanto con las opciones avanzadas ({cmd:by()} y {cmd:weight}) como sin ellas.

{pstd}
{cmd:ginitwfsetup} prepara las variables necesarias para el cálculo del Gini Educativo a partir de la variable {cmd:p10a} de la ENAHO (Encuesta Nacional de Hogares del Perú). Crea las variables {cmd:anios_educ}, {cmd:nivel_educ} y {cmd:xi}.

{pstd}
{cmd:ginitwfeduc} es un comando simplificado para calcular el Gini Educativo para la población que ha terminado su educación (por defecto, mayores de 25 años).

{pstd}
{cmd:ginitwfresumen} muestra un resumen de los últimos resultados calculados y permite guardarlos en un archivo.

{pstd}
{cmd:ginitwfhelp} muestra esta ayuda.

{marker options}{...}
{title:Options}

{dlgtab:Main}
{phang}
{opt type(continuous|discrete)} especifica el tipo de variable. Si no se especifica, el programa intentará inferirlo automáticamente. Para el tipo discrete, es necesario especificar también {opt levels()} y {opt xivar()}.

{phang}
{opt by(varname)} calcula el coeficiente de Gini para cada grupo definido por la variable {it:varname}. Los resultados se presentan en una tabla.

{phang}
{opt levels(varname)} especifica la variable que contiene los niveles educativos (1-8 según Thomas et al., 2001). Requerido para {opt type(discrete)}.

{phang}
{opt xivar(varname)} especifica la variable que contiene los años promedio de educación para cada nivel (valores xi). Requerido para {opt type(discrete)}.

{phang}
{opt educational} es un atajo para especificar {opt type(discrete)}.

{phang}
{opt saving(filename)} guarda los resultados en un archivo Stata. Si se usa con {opt by()}, se guarda una tabla con los resultados por grupo; de lo contrario, se guarda un solo registro.

{phang}
{opt replace} permite reemplazar el archivo si ya existe.

{phang}
{opt noprint} suprime la salida en pantalla. Útil cuando solo se desean los resultados en {cmd:r()}.

{dlgtab:Weight}
{phang}
Los pesos son opcionales y se especifican antes de las opciones. Se admiten los cuatro tipos de pesos de Stata.

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
{cmd:ginitwf} (sin {cmd:by()}) guarda los siguientes resultados en {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(gini)}}coeficiente de Gini{p_end}
{synopt:{cmd:r(mean)}}media de la variable{p_end}
{synopt:{cmd:r(N)}}número de observaciones{p_end}
{synopt:{cmd:r(min)}}valor mínimo{p_end}
{synopt:{cmd:r(max)}}valor máximo{p_end}
{synopt:{cmd:r(sum_w)}}suma de los pesos (si se usan){p_end}
{synopt:{cmd:r(niveles)}}número de niveles (solo discrete){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(var)}}nombre de la variable analizada{p_end}
{synopt:{cmd:r(type)}}tipo de análisis (continuous o discrete){p_end}
{synopt:{cmd:r(method)}}metodología utilizada{p_end}

{pstd}
{cmd:ginitwf} (con {cmd:by()}) guarda adicionalmente:

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results_by)}}matriz con resultados por grupo{p_end}
{synopt:{cmd:r(n_groups)}}número de grupos{p_end}
{synopt:{cmd:r(by_var)}}nombre de la variable de agrupación{p_end}

{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Gini para variables continuas (Deaton, 1997)}:
{pmore}
Para una variable continua {it:x} con {it:n} observaciones, el coeficiente de Gini se calcula como:
{pmore}
{it:G} = (1/{2n(n-1)μ}) Σ_{i=1}^{n} Σ_{j=1}^{n} |x_i - x_j|
{pmore}
donde μ es la media de {it:x}.

{pstd}
{bf:Gini Educativo para variables discretas (Thomas, Wang y Fan, 2001)}:
{pmore}
Para datos discretos agrupados en {it:m} niveles educativos, con proporción de población {it:p_i} y años promedio {it:x_i} en cada nivel:
{pmore}
{it:Ge} = (1/{2μ}) Σ_{i=1}^{m} Σ_{j=1}^{m} p_i p_j |x_i - x_j|
{pmore}
donde μ = Σ_{i=1}^{m} p_i x_i es la media ponderada.

{pstd}
{bf:Ponderación con pesos muestrales}:
{pmore}
Cuando se especifican pesos, las proporciones {it:p_i} se calculan como la suma de pesos en cada nivel dividida por la suma total de pesos.

{marker references}{...}
{title:References}

{pstd}
Deaton, A. 1997. {it:The Analysis of Household Surveys: A Microeconometric Approach to Development Policy}. Baltimore: Johns Hopkins University Press.

{pstd}
Thomas, V., Y. Wang, and X. Fan. 2001. {it:Measuring Education Inequality: Gini Coefficients of Education}. World Bank Policy Research Working Paper No. 2525. Washington, DC: World Bank.

{pstd}
Cuenca, R., and C. E. Urrutia. 2019. Explorando las brechas de desigualdad educativa en el Perú. {it:Revista Mexicana de Investigación Educativa} 24(81): 431-461.

{pstd}
Para una aplicación en el contexto peruano, ver también: Cuenca, R. (2017). {it:Moving toward professional development: the teacher reform in Peru (2012-2016)}. Documento de trabajo No. 235, IEP.

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
