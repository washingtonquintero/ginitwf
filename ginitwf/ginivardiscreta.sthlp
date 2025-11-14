{smcl}
{title:Title}

{phang}
{bf:ginivardiscreta} {hline 2} Calculate educational Gini coefficient for discrete variables using Thomas, Wang & Fan (2001) methodology


{title:Syntax}

{p 8 16 2}
{cmd:ginivardiscreta} {varlist} [{cmd:if}] [{cmd:in}] 
[{cmd:,} {it:options}]

{p 8 16 2}
{cmd:ginisetup} {cmd:,} {opt educ:var(varname)} [{opt nom:brevar(varname)}]

{p 8 16 2}
{cmd:giniresumen} [{varlist}] [{cmd:if}] [{cmd:in}] [{cmd:,} {opt min:obs(#)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt min:obs(#)}}minimum observations per group; default is 100{p_end}
{synopt:{opt show:all}}show all groups including those with insufficient observations{p_end}
{synopt:{opt save(filename)}}save results to specified file{p_end}
{synopt:{opt replace}}overwrite existing file{p_end}
{synopt:{opt detailed}}show detailed calculations{p_end}
{synopt:{opt plot}}generate inequality plot (basic){p_end}
{synopt:{opt level}}show distribution by educational levels{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:ginivardiscreta} calculates the educational Gini coefficient using the 
methodology proposed by Thomas, Wang & Fan (2001) for discrete variables. 
This command is specifically designed for measuring educational inequality 
in years of schooling data.

{pstd}
The package is based on the work of Cuenca & Urrutia (2019) published in the 
Mexican Journal of Educational Research and implements the discrete variable 
version of the Gini coefficient.


{title:Installation}

{pstd}
To install this package:

{phang2}{cmd:. net install ginivardiscreta, from("https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/") replace}


{title:Options for ginivardiscreta}

{phang}
{opt minobs(#)} specifies the minimum number of observations required per group. 
Groups with fewer observations will be skipped. Default is 100.

{phang}
{opt showall} displays all groups, including those with insufficient observations.

{phang}
{opt save(filename)} saves the results to the specified Stata dataset.

{phang}
{opt replace} allows overwriting an existing file when using {cmd:save()}.

{phang}
{opt detailed} shows detailed calculation steps for each group.

{phang}
{opt plot} generates a basic inequality plot.

{phang}
{opt level} shows the distribution across educational levels for each group.


{title:Subcommands}

{phang}
{cmd:ginisetup} automatically creates the required variables {bf:nivel_educ} 
and {bf:xi} from your existing education variable.

{phang}
{cmd:giniresumen} provides a quick summary analysis of educational inequality 
across common grouping variables.


{title:Remarks}

{pstd}
Before using {cmd:ginivardiscreta}, you must have two variables in your dataset:

{p 8 12}{bf:nivel_educ}: Educational level (1-8){p_end}
{p 8 12}{bf:xi}: Years of schooling assigned{p_end}

{pstd}
You can use {cmd:ginisetup} to automatically create these variables from your 
existing education variable.


{title:Examples}

{phang}
Setup variables:{p_end}
{phang2}{cmd:. ginisetup, educvar(años_educacion)}{p_end}

{phang}
Calculate Gini by area:{p_end}
{phang2}{cmd:. ginivardiscreta area, minobs(50)}{p_end}

{phang}
Calculate Gini with level distribution:{p_end}
{phang2}{cmd:. ginivardiscreta genero, level save(resultados) replace}{p_end}

{phang}
Multiple grouping variables:{p_end}
{phang2}{cmd:. ginivardiscreta area genero etnia, minobs(100) showall}{p_end}

{phang}
Quick summary:{p_end}
{phang2}{cmd:. giniresumen, minobs(50)}{p_end}


{title:Stored results}

{pstd}
When using {cmd:save()}, the following variables are stored:

{synoptset 20}{...}
{synopt:{bf:nivel}}Group level identifier{p_end}
{synopt:{bf:gini}}Gini coefficient{p_end}
{synopt:{bf:años_educ}}Average years of education{p_end}
{synopt:{bf:n_obs}}Number of observations{p_end}
{synopt:{bf:variable_grupo}}Grouping variable name{p_end}
{synopt:{bf:etiqueta_grupo}}Group label{p_end}
{synoptline}


{title:References}

{pstd}
Thomas, V., Wang, Y., & Fan, X. (2001). Measuring education inequality: 
Gini coefficients of education. World Bank Policy Research Working Paper.

{pstd}
Cuenca, R., & Urrutia, C. E. (2019). Explorando las brechas de desigualdad 
educativa en el Perú. Revista Mexicana de Investigación Educativa.


{title:Author}

{pstd}
Washington Quintero Montaño{p_end}
{pstd}
Universidad de Guayaquil{p_end}
{pstd}
Email: washington.quinterom@ug.edu.ec{p_end}
{pstd}
Repository: github.com/washingtonquintero/ginitwf{p_end}
{pstd}
Installation: net install ginivardiscreta, from("https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/") replace{p_end}


{title:Also see}

{psee}
Online: {help inequality}, {help ineqdeco} (if installed)
{p_end}
