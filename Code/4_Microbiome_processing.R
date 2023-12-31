
library("phyloseq")
library("knitr")
library("BiocStyle")
library("ggplot2")
library(vegan)

### Combine data into a phyloseq object

otu <- read.csv("otu.csv", header=T, check.names=F, row.names=1)
samdf <- read.csv("samdf.csv", header=T, check.names=F, row.names=1)
taxTab <- read.csv("taxTab.csv", header=T, check.names=F, row.names=1)


ps <- phyloseq(otu_table(otu, taxa_are_rows=FALSE), sample_data(samdf), tax_table(taxTab))
ps <- prune_samples(sample_names(ps) != "Mock", ps) # Remove mock sample
ps


### Taxonomic Filtering 

# Show available ranks in the dataset
rank_names(ps)

### Create table, number of features for each phyla
table(tax_table(ps)[, "Phylum"], exclude = NULL)

ps <- subset_taxa(ps, !is.na(Phylum) & !Phylum %in% c("", "uncharacterized"))

### Define prevalence threshold as 10% of total samples
prevalenceThreshold = 0.1 * nsamples(ps) #-----------------for decontaminated microbial species

prevalenceThreshold = 1 * nsamples(ps) #-----------------for core microbial species

### Execute prevalence filter, using `prune_taxa()` function
keepTaxa = rownames(prevdf1)[(prevdf1$Prevalence >= prevalenceThreshold)]
ps2 = prune_taxa(keepTaxa, ps)
ps2

### Normalize number of reads in each sample using median sequencing depth
total = median(sample_sums(ps2))
standf = function(x, t=total) round(t * (x / sum(x)))
ps2 = transform_sample_counts(ps2, standf)


# Plot abundances
plot_bar(ps2, fill="Phylum")


### Alpha diversity
diversity = estimate_richness(ps2)

data<- cbind(sample_data(ps2), diversity)


### Beta diversity
dist<-  as.matrix(vegdist(otu, method="bray")) 

PCOA <- pcoa(as.dist(dist))
plot3d(PCOA$vectors[, 1:3])

#for category clinical variables
t.test(Shannon ~ $variable, data=data)
boxplot(Shannon ~ $variable, data=data, ylab="Shannon's diversity")

#for continuous clincial variables
result = glm(Shannon ~ $variable, data=data, family="gaussian")
plot(result, which=c(1,2)) 
summary(result)

