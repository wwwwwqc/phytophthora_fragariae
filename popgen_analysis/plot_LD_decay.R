#!/home/adamst/prog/R/R-3.2.5/bin/Rscript

# Load libraries

library("optparse")
library("data.table")
library("ggplot2")

opt_list <- list(
    make_option("--out_file", type = "character",
    help = "Output file for figure to be written to"),
    make_option("--Chromosome_number", type = "integer",
    help = "The number of individuals sampled *
    number of chromosomes sequenced * ploidy"),
    make_option("--LD_statistics", type = "character",
    help = "Output from vcftools LD statistics calling, contains r^2
    and positions of variants"),
    make_option("--units", type = "character",
    help = "Units the distance is measured in, eg. bp, kb, Mb etc."),
    make_option("--window_size", type = "integer",
    help = "Window size used for calculating LD statistics,
    used as largest bin maximum size"),
    make_option("--bin_size", type = "integer",
    help = "Size of bin for data to be put in"),
    make_option("--Cstart", type = "double",
    help = "Starting value for C, recommended 0.1")
)

opt <- parse_args(OptionParser(option_list = opt_list))
outfile <- opt$out_file
n <- opt$Chromosome_number
LD_file <- opt$LD_statistics
units <- opt$units
Cstart <- opt$Cstart
window_size <- opt$window_size
bin_size <- opt$bin_size

# Parse output file into necessary variables

input <- read.table(LD_file, header = TRUE)

input$Distance <- input$POS2 - input$POS1

# Bin data

data <- c(tapply(input$R.2, cut(input$Distance, seq(0, window_size,
    by = bin_size)), mean))
data_df <- data.frame(data)
setDT(data_df, keep.rownames = TRUE)
colnames(data_df) <- c("Distance", "Rsqd")

brks <- seq(0, window_size, bin_size)
Max_val <- window_size / bin_size
ints <- seq(1, Max_val, by = 1)
data_df$midpoint <- (head(brks, -1) + diff(brks) / 2)[ints]
Rsqd <- data_df$Rsqd
midpoint <- data_df$midpoint
Cstart <- c(C = Cstart)

# Fit binned data to Hills and Weir decay function (a non-linear model)
# Following code in script adapted from
# https://jujumaan.com/2017/07/15/linkage-disequilibrium-decay-plot/

modelC <- nls(Rsqd~ ( (10 + C * midpoint) / ( (2 + C * midpoint) * (11 + C *
    midpoint))) * (1 + ( (3 + C * midpoint) * (12 + 12 * C * midpoint + (C *
        midpoint) ^ 2)) / (n * (2 + C * midpoint) * (11 + C * midpoint))),
        start = Cstart, control = nls.control(maxiter = 100))

# extract rho, the recombination parameter, 4Nr

rho <- summary(modelC)$parameters[1]

# Use the new rho value to obtain LD values adjusted for their distances

newrsqd <- ( (10 + rho * data_df$midpoint) / ( (2 + rho * data_df$midpoint) *
(11 + rho * data_df$midpoint))) * (1 + ( (3 + rho * data_df$midpoint) * (12 +
    12 * rho * data_df$midpoint + (rho * data_df$midpoint) ^ 2)) / (n * (2 +
        rho * data_df$midpoint) * (11 + rho * data_df$midpoint)))

fitted_data <- data.frame(data_df$midpoint, newrsqd)
max_rsqd <- max(fitted_data$newrsqd)
half_decay <- max_rsqd * 0.5
half_decay_dist <- fitted_data$data_df.midpoint[which.min(abs(
    fitted_data$newrsqd - half_decay))]
fitted_data <- fitted_data[order(fitted_data$data_df.midpoint), ]

# Identify point where r^2 = 0.2

rsqd_pt2 <- fitted_data$data_df.midpoint[which.min(abs(fitted_data$newrsqd
    - 0.2))]

cat("Half decay distance of LD r^2:", half_decay_dist, units, "\n")
cat("Distance where r^2 = 0.2:", rsqd_pt2, units, "\n")

# Plot decay curve and add intercept lines

Decay_plot <- ggplot(data = fitted_data, aes(x = midpoint, y = newrsqd)) +
geom_line(colour = "blue") + geom_vline(xintercept = half_decay_dist, colour =
    "green", linetype = "dotted") + geom_hline(yintercept = half_decay,
        colour = "green", linetype = "dotted") + geom_vline(xintercept =
            rsqd_pt2, colour = "red", linetype = "dotted") +
            geom_hline(yintercept = 0.2, colour = "red", linetype = "dotted") +
            labs(x = "Physical Distance (bp)", y =
            "Fitted linkage disequilibrium") + theme(panel.grid.major =
                element_blank(), panel.grid.minor = element_blank(),
                panel.background = element_blank(), panel.border =
                element_rect(colour = "black", fill = NA, size = 1))

ggsave(outfile, Decay_plot, width = 21, height = 7)