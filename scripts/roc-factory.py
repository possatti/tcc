#!/usr/bin/env python3

from __future__ import absolute_import, division, print_function, unicode_literals
import matplotlib.pyplot as plt
import numpy as np

# Useful resources:
#  - http://stackoverflow.com/questions/25009284/how-to-plot-roc-curve-in-python
#  - http://scikit-learn.org/stable/auto_examples/model_selection/plot_roc.html

instances = [
    ('p', 0.9),
    ('p', 0.8),
    ('n', 0.7),
    ('p', 0.6),
    ('p', 0.55),
    ('p', 0.54),
    ('n', 0.53),
    ('n', 0.52),
    ('p', 0.51),
    ('n', 0.505),
    ('p', 0.4),
    ('n', 0.39),
    ('p', 0.38),
    ('n', 0.37),
    ('n', 0.36),
    ('n', 0.35),
    ('p', 0.34),
    ('n', 0.33),
    ('p', 0.30),
    ('n', 0.1),
]

def calculate_roc_points(instances):
    ''''''

    # Calculate the number of positives and negatives (the real ones).
    P = N = 0
    for label, score in instances:
        if label == 'p':
            P += 1
        else:
            N += 1

    # Calculate each point.
    TP = FP = 0
    points = []
    for label, score in instances:
        if label == 'p':
            TP += 1
        else:
            FP +=1
        point = (FP/N, TP/P)
        points.append(point)
    return points

def create_roc_curve_graph(points):
    xs = []
    ys = []
    for x, y in points:
        xs.append(x)
        ys.append(y)

    # This is the AUC
    auc = np.trapz(ys,xs)
    print("AUC =", auc)

    # This is the ROC curve
    lines = plt.plot([0,1], [0,1], color="black", ls='--', lw=0.5)
    lines = plt.plot(xs, ys, 'bx-', lw=1, label='ROC curve (area = %0.2f)' % auc)
    # plt.title("Exemplo de Curva ROC")
    plt.xlabel("fp rate")
    plt.ylabel("tp rate")
    plt.legend(loc="lower right")
    plt.axis([0, 1, 0, 1])
    plt.grid(True)
    plt.show()
    # plt.savefig('foo.png', bbox_inches='tight')

points = calculate_roc_points(instances)
for point in points:
    print(point)
create_roc_curve_graph(points)



