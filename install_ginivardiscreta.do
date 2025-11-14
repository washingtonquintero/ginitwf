* install_ginivardiscreta.do
* Installation script for ginivardiscreta package

display "Installing ginivardiscreta package..."
display "Gini para Variables Discretas - Thomas, Wang & Fan (2001)"
display "Autor: Washington Quintero Montaño - Universidad de Guayaquil"
display "Repository: github.com/washingtonquintero/ginitwf"

* Instalar desde GitHub con la ruta correcta
net install ginivardiscreta, from("https://raw.githubusercontent.com/washingtonquintero/ginitwf/refs/heads/main/ginitwf/") replace

display " "
display "=================================================="
display "ginivardiscreta PACKAGE INSTALLED SUCCESSFULLY"
display "=================================================="
display "Autor: Washington Quintero Montaño"
display "Universidad de Guayaquil"
display "Email: washington.quinterom@ug.edu.ec"
display "Repositorio: github.com/washingtonquintero/ginitwf"
display " "
display "Available commands:"
display "  {bf:ginivardiscreta} - Main command for Gini calculation"
display "  {bf:ginisetup}       - Automatic variable setup"
display "  {bf:giniresumen}     - Quick summary analysis"
display " "
display "Getting started:"
display "1. ginisetup, educvar(your_education_var)"
display "2. ginivardiscreta group_var"
display "3. giniresumen (for quick analysis)"
display " "
display "For complete documentation: {bf:help ginivardiscreta}"
