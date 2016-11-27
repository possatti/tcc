#!/usr/bin/env python3

from __future__ import absolute_import, division, print_function, unicode_literals
import matplotlib.pyplot as plt
import numpy as np
import fileinput
import re

## Expected input:
# ,f5,steghide,outguess,stepic,lsbsteg,
# 0%,1,1,1,0,0,
# 10%,0,1,0,1,0,
# 20%,0,1,0,1,1,
# 30%,0,1,1,3,3,
# 40%,0,1,0,6,11,
# 50%,0,1,0,10,17,
# 60%,0,0,1,15,20,
# 70%,0,0,0,18,23,
# 80%,0,1,0,22,26,
# 90%,0,0,0,24,28,
# 100%,0,1,0,26,29,

xs = []
f5_ys = []
steghide_ys = []
outguess_ys = []
stepic_ys = []
lsbsteg_ys = []

# Parse input into xs and ys.
for line in fileinput.input():
    if re.match(r'^\d+%', line):
        pieces = line.split(sep=',')

        # Remove the '%' symbol and add the percentage to x axis.
        match_percentage = re.match(r'^(\d+)%', pieces[0])
        percentage = int(match_percentage.group(1))
        # print("Percentage:", percentage)
        xs.append(percentage)

        # The values for the tools.
        f5_ys.append(int(pieces[1]))
        steghide_ys.append(int(pieces[2]))
        outguess_ys.append(int(pieces[3]))
        stepic_ys.append(int(pieces[4]))
        lsbsteg_ys.append(int(pieces[5]))

# Debug
print("xs:", xs)
print("f5_ys:", f5_ys)
print("steghide_ys:", steghide_ys)
print("outguess_ys:", outguess_ys)
print("stepic_ys:", stepic_ys)
print("lsbsteg_ys:", lsbsteg_ys)

# This is the ROC curve
lines = plt.plot(xs, f5_ys,       color='Brown', lw=2, label='F5')
lines = plt.plot(xs, steghide_ys, color='Red', lw=2, label='Steghide')
lines = plt.plot(xs, outguess_ys, color='Yellow', lw=2, label='Outguess')
lines = plt.plot(xs, stepic_ys,   color='Green', lw=2, label='Stepic')
lines = plt.plot(xs, lsbsteg_ys,  color='Blue', lw=2, label='LSBSteg')
# plt.title("Número de imagens detectadas por porcentagem embutida")
plt.xlabel("Porcentagem embutida (%)")
plt.ylabel("Número de imagens detectadas")
plt.legend(loc="upper left")
# plt.axis([0, 100, 0, 30])
plt.grid(True)
# plt.show()
plt.savefig('grafico-imagens-detectadas.png', bbox_inches='tight')
