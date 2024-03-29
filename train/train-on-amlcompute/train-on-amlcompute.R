# Copyright(c) Microsoft Corporation.
# Licensed under the MIT license.

library(azuremlsdk)

# Reminder: set working directory to current file location prior to running this script
setwd("~/azure-machine-learning-r/train/train-on-amlcompute")

ws <- load_workspace_from_config(path = "../../")

ds <- get_default_datastore(ws)

# Upload iris data to the datastore
target_path <- "irisdata"
upload_files_to_datastore(ds,
                          list("./iris.csv"),
                          target_path = target_path,
                          overwrite = TRUE)

# Create AmlCompute cluster
cluster_name <- "rcluster"
compute_target <- get_compute(ws, cluster_name = cluster_name)
if (is.null(compute_target)) {
  vm_size <- "STANDARD_D2_V2"
  compute_target <- create_aml_compute(workspace = ws,
                                       cluster_name = cluster_name,
                                       vm_size = vm_size,
                                       max_nodes = 1)

  wait_for_provisioning_completion(compute_target, show_output = TRUE)
}

# Define estimator
est <- estimator(source_directory = ".",
                 entry_script = "train-remote.R",
                 script_params = list("--data_folder" = ds$path(target_path)),
                 compute_target = compute_target)

experiment_name <- "train-r-script-on-amlcompute"
exp <- experiment(ws, experiment_name)

# Submit job and display the run details
run <- submit_experiment(exp, est)
view_run_details(run)
wait_for_run_completion(run, show_output = TRUE)

# Get the run metrics
metrics <- get_run_metrics(run)
metrics

get_run_file_names(run)
download_file_from_run(run, name = "outputs/model.rds", output_file_path = "./model-iris.rds")

# Delete cluster
delete_compute(compute_target)

