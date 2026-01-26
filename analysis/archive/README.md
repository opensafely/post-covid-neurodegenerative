This directory serves as a means to archive files no longer used in the overall [repository](https://github.com/opensafely/post-covid-neurodegenerative), please see the [`README.md`](./README.md) file for further information.

This directory contains 3 directories which were used to test the project during development, they are not needed in the final output. 
We also include a way to reproduce the actions needed to run the scripts if necessary.

 - [`Code Diagnostics`](./analysis/archive/code_diagnostics) was made to provide the summary description for a particular outcome or outcome set. It goes through the three dataset_definition outputs, only loads in the relevant columns, and applies the skim() function to them.
 
 - [`Dataset Definition RSD`](./analysis/archive/dataset_definition_rsd) was created as a reduced version of the general dataset_definition, which would only load data relevant to REM Sleep disorder. The structure mimics the dataset_definition directory in the main project.
 
 - [`Table Age`](./analysis/archive/table_age) calculated the counts of outcome in customizable age groups, and was used to help define age boundaries
 
 The other files in the repository are:
 - [`create_archive_project_actions.R`](./analysis/create_project_actions.R) is the function which creates the [`project_archive.yaml`](./analysis/archive/project_archive.yaml), the list of actions corresponding to the scripts in this folder (with dependencies)
     
 - [`project_archive.yaml`](./analysis/archive/project_archive.yaml), which defines run-order and dependencies for all the analysis scripts. Unlike the core [`project.yaml`](./project.yaml) file, this file serves as an archive of actions rather than something to run in OpenSAFELY