library(LCMCR)
source("helper_functions.R")

# Example 4c the simulation of Manrique-Vallier (2016) and adding in a third 
# class

#### Set latent class model parameters ####

# Number of lists
K <- 5
# Number of classes
J <- 3
# Class probabilities 
nu <- c(0.7, 0.2, 0.1)
# Class specific observation probabilities 
q <- matrix(c(0.033, 0.033, 0.099, 0.132, 0.033,
              0.275, 0.25, 0.2, 0.3, 0.325,
              0.66, 0.825, 0.759, 0.99, 0.693), ncol = K, byrow = TRUE)
# Cell probabilities
pis <- exp(get_log_pis(nu, q, K))
# Missing cell probabilities
pi_0 <- pis[1]
# Conditional cell probabilities
pi_tilde <- pis[2:(2 ^ K)] / (1- pi_0)

#### Run simulation ####

# Simulation settings
num_rep <- 200
num_dpmm_burn <- 50000
num_dpmm <- 200000
Ns <- c(2000, 10000, 100000)
results_N <- vector("list", length(Ns))
results_pi_0 <- vector("list", length(Ns))
# Run Simulation
for(i in 1:length(Ns)){
    results_N[[i]] <- matrix(0, nrow = num_rep, ncol = 6)
    results_pi_0[[i]] <- matrix(0, nrow = num_rep, ncol = 6)
    for(j in 1:num_rep){
        print(paste0("Iteration ", j, ", N = ", Ns[i]))
        data <- generate_lcm_data(Ns[i], nu, q, K, seed = j + i)
        data_obs <- data[rowSums(data) > 0,]
        fit_dpmm <- fit_lcmcr(data_obs, K, burn_iter = num_dpmm_burn, 
                              samp_iter = num_dpmm, K_star = J, seed = 64, 
                              tab = FALSE, a = 0.25, b = 0.25)
        pi_0_dpmm <- fit_dpmm$Get_Trace('prob_zero')
        N_dpmm <- nrow(data_obs) + fit_dpmm$Get_Trace('n0')
        results_N[[i]][j, ] <- c(mean(N_dpmm), 
                                 quantile(N_dpmm, 
                                          prob = c(0.5, 0.025, 0.975,
                                                   0.25, 0.75)))
        results_pi_0[[i]][j, ] <- c(mean(pi_0_dpmm), 
                                    quantile(pi_0_dpmm, 
                                             prob = c(0.5, 0.025, 0.975,
                                                      0.25, 0.75)))
        if(j %% 10 == 0){
            save(results_N, results_pi_0, file = "example_4c_simulation.RData")
        }
    }
}

#### Summarize Simulation ####

for(i in 1:length(Ns)){
    print(paste0("Example 4c: Population Size " , Ns[i], " Results"))
    print(paste0("Mean Posterior Median: ", mean(results_pi_0[[i]][, 2])))
    print(paste0("95% Credible Interval Coverage: ", 
                 mean(results_pi_0[[i]][, 4] > pi_0 & 
                          results_pi_0[[i]][, 3] < pi_0)))
    print(paste0("Mean 95% Credible Interval Width: ", 
                 mean(results_pi_0[[i]][, 4] - results_pi_0[[i]][, 3])))
    print(paste0("50% Credible Interval Coverage: ", 
                 mean(results_pi_0[[i]][, 6] > pi_0 & 
                          results_pi_0[[i]][, 5] < pi_0)))
    print(paste0("Mean 50% Credible Interval Width: ", 
                 mean(results_pi_0[[i]][, 6] - results_pi_0[[i]][, 5])))
}
