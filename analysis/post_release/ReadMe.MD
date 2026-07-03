In this folder, you will find scripts to visualise and process the data from the post-covid-neurodegenerative project.

You will have to download the data from jobs.opensafely.org (here)[https://jobs.opensafely.org/investigating-events-following-covid-19/post-covid-neurodegenerative-v3/outputs/latest/]

You will need to create a folder called `analysis\specify_paths.R`, which defines 5 variables:
release - the filepath to the directory you are storing the downloaded outputs
path_aer_input - the path to the aer file
path_table1 - the path to the table1 file
path_table2 - the path to the table2 file
path_venn - the path to the venn file

Please run the most relevant script with `post_release\YYYYMMDD_output_preprocessing.R` to do some initial processing on the folder. You may have to rename your path_* files in `analysis\specify_paths.R` to account for this.

You should then be able to run `post_release\run_post_release.R` to generate all the tables and figures.