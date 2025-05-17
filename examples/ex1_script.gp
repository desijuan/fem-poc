set datafile separator ','
set key autotitle columnhead

set terminal pngcairo enhanced size 800,600
set output "ex1_plot.png"

set xlabel "Displacement (m)"
set ylabel "Height (m)"

set xrange [0:0.5]
set yrange [0:10.36]

set grid

set style line 1 lw 3 lt rgb "#26dfd0"

plot 'ex1_data.csv' using 2:1 with lines ls 1 notitle
set output  # Close the output file
