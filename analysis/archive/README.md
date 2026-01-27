# post-covid-neurodegenerative archive

This directory serves as a means to archive files no longer used in the overall [repository](https://github.com/opensafely/post-covid-neurodegenerative), please see the [`README.md`](./README.md) file for further information.

## Repository navigation

This directory contains 3 directories which were used to test the project during development, they are not needed in the final output. We also include a way to reproduce the actions needed to run the scripts if necessary.

-   [`code_diagnostics`](./analysis/archive/code_diagnostics) was made to provide the summary description for a particular outcome or outcome set. It goes through the three dataset_definition outputs, only loads in the relevant columns, and applies the skim() function to them.

-   [`dataset_definition_rsd`](./analysis/archive/dataset_definition_rsd) was created as a reduced version of the general dataset_definition, which would only load data relevant to REM Sleep disorder. The structure mimics the dataset_definition directory in the main project.

-   [`table_age`](./analysis/archive/table_age) calculated the counts of outcome in customizable age groups, and was used to help define age boundaries

The other files in the repository are:

-   [`create_archive_project_actions.R`](./analysis/archive/create_archive_project_actions.R) is the function which creates the [`project_archive.yaml`](./analysis/archive/project_archive.yaml), the list of actions corresponding to the scripts in this folder (with dependencies)

-   [`project_archive.yaml`](./analysis/archive/project_archive.yaml), which defines run-order and dependencies for all the analysis scripts. Unlike the core [`project.yaml`](./project.yaml) file, this file serves as an archive of actions rather than something to run in OpenSAFELY

## Running the code

In order to run these actions, please first move the relevant directory (e.g. `table_age`) into the [`analysis`](./analysis) directory, and then either:

a)  Copy the relevant text from [`create_archive_project_actions.R`](./analysis/archive/create_archive_project_actions.R) into [`create_project_actions.R`](./analysis/create_project_actions.R) and rerun the file locally to load the new actions into the core [`project.yaml`](./project.yaml) file

```         
e.g. For table age, you would copy both the `table_age` function and the later lines within `actions_list <- splice(` under the heading `## Table Age` and past them into an appropriate ordering in create_project_actions (after any dependencies).
```

b)  Copy the relevant text from [`project_archive.yaml`](./analysis/archive/project_archive.yaml) into the core [`project.yaml`](./project.yaml) file, making sure to place it after any dependent actions

```         
e.g. copy the 4 actions containing `table_age` (such as table_age-cohort_prevax), and making sure to paste them after the study_dates and generate_input_vax_clean actions. Remember to properly indent the actions within the .yaml file.
```

The first approach (editing [`create_project_actions.R`](./analysis/create_project_actions.R)) is the preferred approach, as the second approach can be overwritten if [`create_project_actions.R`](./analysis/create_project_actions.R) is ever rerun.

## Release

A version of the code with these actions+directories within the main analysis can be found preserved as [`post-covid-neurodegenerative-v2_all-actions`](https://github.com/opensafely/post-covid-neurodegenerative/releases/tag/v2)