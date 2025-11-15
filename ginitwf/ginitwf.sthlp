{smcl}
{title:Title}

{phang}
{bf:ginitwf} {hline 2} Calculate Gini coefficient for discrete variables

{title:Syntax}

{p 8 16 2}
{cmd:ginitwfsetup} {cmd:,} {opt var:iable(varname)}

{p 8 16 2}
{cmd:ginitwfeduc} {cmd:,} {opt var:iable(varname)}

{p 8 16 2}
{cmd:ginitwf} {varlist} [{cmd:,} {opt min:obs(#)} {opt show:all} {opt save(filename)} {opt replace}]

{title:Description}

{pstd}
{bf:ginitwf} calculates the Gini coefficient using the 
methodology proposed by Thomas, Wang & Fan (2001) for discrete variables.

{pstd}
The package provides specialized configuration for educational variables
using the standardized values from Thomas et al. methodology.

{title:Options for ginitwf}

{phang}
{opt minobs(#)} specifies the minimum number of observations per group.

{phang}
{opt showall} shows all groups including those with insufficient observations.

{phang}
{opt save(filename)} saves results to specified file.

{phang}
{opt replace} overwrites existing file.

{title:Examples}

{pstd}
Setup generic variable:{p_end}
{phang2}{cmd:. ginitwfsetup, variable(income)}{p_end}

{pstd}
Setup educational variable:{p_end}
{phang2}{cmd:. ginitwfeduc, variable(education_years)}{p_end}

{pstd}
Analyze inequality:{p_end}
{phang2}{cmd:. ginitwf province, minobs(50)}{p_end}

{title:Author}

{pstd}
Washington Quintero Montaño{p_end}
{pstd}
Universidad de Guayaquil{p_end}
{pstd}
Email: washington.quinterom@ug.edu.ec{p_end}
