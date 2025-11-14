{smcl}
{title:Title}

{phang}
{bf:ginivardiscreta} {hline 2} Calculate Gini coefficient for generic discrete variables using Thomas, Wang & Fan (2001) methodology


{title:Syntax}

{p 8 16 2}
{cmd:ginivardiscreta} {varlist} [{cmd:if}] [{cmd:in}] 
[{cmd:,} {it:options}]

{p 8 16 2}
{cmd:giniconfig} {cmd:,} {opt var:iable(varname)} [{opt val:ores(numlist)} {opt prop:orciones(numlist)} {opt auto:matic}]

{p 8 16 2}
{cmd:ginieducacion} {cmd:,} {opt var:iable(varname)}

{p 8 16 2}
{cmd:giniresumen} [{varlist}] [{cmd:if}] [{cmd:in}] [{cmd:,} {opt min:obs(#)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt min:obs(#)}}minimum observations per group; default is 30{p_end}
{synopt:{opt show:all}}show all groups including those with insufficient observations{p_end}
{synopt:{opt save(filename)}}save results to specified file{p_end}
{synopt:{opt replace}}overwrite existing file{p_end}
{synopt:{opt detailed}}show detailed calculations{p_end}
{synopt:{opt plot}}generate inequality plot (basic){p_end}
{synopt:{opt val:ores}}show value distribution{p_end}
{synopt:{opt prop:orciones}}show proportion distribution{p_end}
{synopt:{opt nocon:fig}}use without automatic configuration{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:ginivardiscreta} calculates the Gini coefficient using the 
methodology proposed by Thomas, Wang & Fan (2001) for generic discrete variables. 
This command can be used for educational variables, income categories, 
health indicators, and any other discrete variable.


{title:Installation}

{pstd}
To install this package:

{phang2}{cmd:. net install ginivardiscreta, from("https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/") replace}


{title:Subcommands}

{phang}
{cmd:giniconfig} automatically configures your discrete variable for Gini calculation.
Use {opt automatic} for simple numeric variables or specify {opt valores()} and 
{opt proporciones()} for custom distributions.

{phang}
{cmd:ginieducacion} provides specific configuration for educational variables
using Thomas, Wang & Fan (2001) methodology.

{phang}
{cmd:giniresumen} provides a quick summary analysis of inequality 
across common grouping variables.


{title:Examples}

{phang}
Generic configuration for income categories:{p_end}
{phang2}{cmd:. giniconfig, variable(ingreso) automatic}{p_end}
{phang2}{cmd:. ginivardiscreta region, minobs(50)}{p_end}

{phang}
Custom configuration with values and proportions:{p_end}
{phang2}{cmd:. giniconfig, variable(estrato) valores(1 2 3 4 5) proporciones(0.1 0.2 0.4 0.2 0.1)}{p_end}

{phang}
Educational configuration:{p_end}
{phang2}{cmd:. ginieducacion, variable(años_educacion)}{p_end}
{phang2}{cmd:. ginivardiscreta area genero, valores proporciones}{p_end}

{phang}
Quick summary:{p_end}
{phang2}{cmd:. giniresumen, minobs(30)}{p_end}


{title:Author}

{pstd}
Washington Quintero Montaño{p_end}
{pstd}
Universidad de Guayaquil{p_end}
{pstd}
Email: washington.quinterom@ug.edu.ec{p_end}
{pstd}
Repository: github.com/washingtonquintero/ginitwf{p_end}
