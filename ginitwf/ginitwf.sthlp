{smcl}
{* *! version 1.0.0 30-Mar-2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "ginitwf##syntax"}{...}
{viewerjumpto "Description" "ginitwf##description"}{...}
{viewerjumpto "Options" "ginitwf##options"}{...}
{viewerjumpto "Examples" "ginitwf##examples"}{...}
{viewerjumpto "Saved results" "ginitwf##saved_results"}{...}
{viewerjumpto "References" "ginitwf##references"}{...}
{viewerjumpto "Author" "ginitwf##author"}{...}
{title:Title}

{phang}
{bf:ginitwf} {hline 2} Calcula coeficientes de Gini para variables continuas (Deaton, 1997) y Gini Educativo para variables discretas (Thomas, Wang & Fan, 2001)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:ginitwf} {varname} [{cmd:if}] [{cmd:in}] [{cmd:,} {opt type(continuous|discrete)} {opt levels(varname)} {opt xivar(varname)}]

{p 8 17 2}
{cmdab:ginitwfsetup}

{p 8 17 2}
{cmdab:ginitwfeduc} [{cmd:if}] [{cmd:in}]

{p 8 17 2}
{cmdab:ginitwfresumen} [{cmd:,} {opt save(filename)} {opt replace}]

{p 8 17 2}
{cmdab:ginitwfhelp}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt type}}especifica tipo de variable: continuous o discrete{p_end}
{synopt:{opt levels}}para tipo discrete: variable de niveles educativos{p_end}
{synopt:{opt xivar}}para tipo discrete: variable con años por nivel{p_end}

{syntab:Resumen}
{synopt:{opt save}}guarda resultados en archivo .dta{p_end}
{synopt:{opt replace}}reemplaza archivo existente{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ginitwf} es un paquete Stata para calcular desigualdades educativas mediante coeficientes de Gini. 
Implementa dos metodologías principales:

{pstd}
1. {bf:Gini para variables continuas}: Basado en Deaton (1997), utiliza la fórmula:
   G = 1/(2n(n-1)μ) ΣΣ |x_i - x_j|
   Ideal para variables como gasto educativo per cápita.

{pstd}
2. {bf:Gini Educativo para variables discretas}: Basado en Thomas, Wang & Fan (2001), utiliza:
   Ge = 1/(2μ) ΣΣ p_i p_j |x_i - x_j|
   Diseñado específicamente para años de educación agrupados en niveles.

{pstd}
El paquete incluye comandos auxiliares para preparar datos ({cmd:ginitwfsetup}), 
calcular Gini Educativo de forma simplificada ({cmd:ginitwfeduc}), 
y mostrar resúmenes ({cmd:ginitwfresumen}).

{marker options}{...}
{title:Options}

{dlgtab:Main}
{phang}
{opt type(continuous|discrete)} especifica el tipo de variable. Si no se especifica, 
el programa intenta inferirlo automáticamente basado en el número de valores únicos.

{phang}
{opt levels(varname)} variable que contiene los niveles educativos (1-8 según Thomas et al.). 
Requerido para {opt type(discrete)}.

{phang}
{opt xivar(varname)} variable que contiene los años de educación promedio para cada nivel. 
Requerido para {opt type(discrete)}.

{dlgtab:Resumen}
{phang}
{opt save(filename)} guarda los resultados en un archivo .dta especificado.

{phang}
{opt replace} permite reemplazar el archivo si ya existe.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto, clear}{p_end}
{phang}{cmd:. ginitwf price, type(continuous)}{p_end}

{phang}{cmd:. * Para datos educativos ENAHO:}{p_end}
{phang}{cmd:. ginitwfsetup}{p_end}
{phang}{cmd:. ginitwf anios_educ, type(discrete) levels(nivel_educ) xivar(xi)}{p_end}

{phang}{cmd:. * Versión simplificada:}{p_end}
{phang}{cmd:. ginitwfeduc if edad >= 25}{p_end}

{phang}{cmd:. * Ver resumen y guardar:}{p_end}
{phang}{cmd:. ginitwfresumen, save(resultados_gini) replace}{p_end}

{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:ginitwf} guarda los siguientes resultados en {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(gini)}}coeficiente de Gini{p_end}
{synopt:{cmd:r(mean)}}media de la variable{p_end}
{synopt:{cmd:r(N)}}número de observaciones{p_end}
{synopt:{cmd:r(niveles)}}número de niveles educativos (solo discrete){p_end}

{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(type)}}tipo de análisis (continuous/discrete){p_end}
{synopt:{cmd:r(method)}}metodología utilizada{p_end}
{synopt:{cmd:r(var)}}nombre de la variable analizada{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}matriz con resultados principales{p_end}
{p2colreset}{...}

{marker references}{...}
{title:References}

{pstd}
Deaton, A. (1997). {it:The Analysis of Household Surveys: A Microeconometric Approach to Development Policy}. 
Baltimore: Johns Hopkins University Press.

{pstd}
Thomas, V., Wang, Y., & Fan, X. (2001). {it:Measuring Education Inequality: Gini Coefficients of Education}. 
World Bank Policy Research Working Paper No. 2525.

{marker author}{...}
{title:Author}

{pstd}
Washington Quintero{p_end}
{pstd}
Universidad de Guayaquil{p_end}
{pstd}
Email: washington.quintero@ug.edu.ec{p_end}
{pstd}
GitHub: {browse "https://github.com/washingtonquintero/ginitwf":https://github.com/washingtonquintero/ginitwf}{p_end}

{title:Also see}

{pstd}
Online: {help ineqdeco} (si está instalado){p_end}
{pstd}
Recursos adicionales: {browse "https://gptonline.ai/"}{p_end}
