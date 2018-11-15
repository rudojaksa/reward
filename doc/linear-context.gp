set terminal pngcairo enhanced size 940,400 font 'Noto Mono,13' rounded
set output 'linear-context.png'
set border linewidth 1.3

r0=0.0
rn=1.0
a0=1.0
an=7.0

rd=rn-r0
ad=an-a0

print sprintf("r0=%.2f rn=%.2f rd=%.2f",r0,rn,rd)
print sprintf("a0=%.2f an=%.2f ad=%.2f",a0,an,ad)

set xrange [a0:an]
set yrange [-0.1:1.3]
set key center top
set title "linear context-shift equations      r0=0  rn=1     a0=1  an=7     rd=rn-r0  ad=an-a0"

plot \
 1.0*rd/ad*(x-a0)+r0+rd*0.00 lw 2 lc rgb '#F00000',\
 0.5*rd/ad*(x-a0)+r0+rd*0.25 lw 2 lc rgb '#F04040',\
 0.0*rd/ad*(x-a0)+r0+rd*0.50 lw 2 lc rgb '#F08080',\
-0.5*rd/ad*(x-a0)+r0+rd*0.75 lw 2 lc rgb '#F0B0B0',\
-1.0*rd/ad*(x-a0)+r0+rd*1.00 lw 2 lc rgb '#F0D0D0'

