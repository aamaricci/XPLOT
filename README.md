## _PLOT_

### XmGrace from command-line, *i.e.* a perl wrapper of the xmgrace plotting tool. 

*(c) Adriano Amaricci 2015*

Version 2.1 [17.Aug.2015]

#### xplot [options] [files/stdin]
#### Options:   
- `-x<min:max>`   [specify x-interval as xmin:xmin, e.g. `-x0:10a]
- `-y<min:max>`   [specify y-interval as ymin:ymin, e.g. `-y-2:1`]
- `-lx`           [set the x log-scale]
- `-ly`           [set the y log-scale]
- `-lw<#>`        [set line width at #, e.g. `-lw3`]
- `-uX:Yn/F(Yn)`  [set the x,y  nth-columns, e.g. `-u1:3`; `-u1:2,1:3`; `-uall`; `-uone/-u1`; `-u1:'cos($2)'`]
- `-m[w:h]`       [set fixed window format (default free) optional[wdith:height]]
- `-show`         [print cmd line on std.out]
- `-s<file>`      [save output to file.agr]
- `-t<string>`    [set title]
- `-xt<string>`   [set x-label]
- `-yt<string>`   [set y-label]
- `-l`            [turn legend on]
- `-d`            [turn legend on using directories]
- `-k`            [put a string on the y-axis stride for each data sets]
- `-w<l,p,lp>`    [set line type (gnuplot style) with line (default), with points, both]
- `-c<C1:C2>`     [use a gradient between color C1 [default black] and color C2 [default red]
- `-h`            [this help]

####Usage:
[... | ] **xplot** *[options]* ==[files/stdin]==

 `$ xplot data`
 
 `$ xplot -u1:3 -x-1:1 data.1* -u1:2  data.0`

 `$ cat data | xplot -uall`

 `$ seq -f%1.4f 0 0.01 6.28 | xplot -u1:'cos($1)' -show`
