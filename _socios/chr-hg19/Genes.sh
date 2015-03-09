% chromosomes 1-Y were downloaded from genome browser.
% this script will make a gene list appropriate for
% snippeep

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y; do cat /Users/roberto/Downloads/chr/chr$i |awk 'NR>1{print $5,$6,$13}';done>~/Downloads/chr/Genes.txt

awk 'BEGIN{i=0}FNR==1{print NR-1}' $(for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y; do echo -n /Users/roberto/Downloads/chr/chr$i" ";done)
