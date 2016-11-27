#!/usr/bin/env python3

from __future__ import absolute_import, division, print_function, unicode_literals
import matplotlib.pyplot as plt
import numpy as np
import argparse
import re
import os

# Describe arguments and options.
parser = argparse.ArgumentParser(description='Create ROC curves based on StegExpose reports.')
parser.add_argument("reports_dir", help="Path to the StegExpose reports.")

# Parse argumets.
args = parser.parse_args()

def get_instances_from_report(report_file_path):
    """
    Parse StegExpose report and return a list of (class, score).
    E.g. [('p', 0.10), ('n', 0.05)]
    """

    instances = []
    with open(report_file_path, 'r') as report_file:
        for line in report_file:
            # Filter the lines without images.
            if re.match(r'.*\.(png|jpg),', line):
                # Get the important data.
                pieces = line.split(sep=',')
                image_name = pieces[0]
                real_class = 'p' if re.match(r'.*_\d+p\.(png|jpg),', line) else 'n'
                fusion_score = float(pieces[-1])
                # print(real_class, fusion_score, image_name)
                instances.append((real_class, fusion_score))
    return instances

def calculate_roc_points(instances):
    """From a sorted list of instances, calculate the points that draw the ROC curve."""

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

def calculate_discrete_classifier_point(instances, threshold):
    """
    From a list of instances, calculate the coordinates for a discrete classifier
    that uses the given threshold.
    """

    TP = 0  # True positives
    FP = 0  # False positives
    P = 0  # Total positives
    N = 0  # Total negatives
    for label, score in instances:
        if label == 'p':
            P += 1
            # Is it classified as positive?
            if score >= threshold:
                TP += 1
        else:
            N += 1
            # Is it classified as positive? Even though it is not!
            if score >= threshold:
                FP += 1
    tp_rate = TP / P
    fp_rate = FP / N
    return (fp_rate, tp_rate)

# Parse instance data out of StegExpose reports.
clean_png_instances = get_instances_from_report(os.path.join(args.reports_dir, 'clean-png.csv'))
clean_jpg_instances = get_instances_from_report(os.path.join(args.reports_dir, 'clean-jpeg.csv'))
steghide_instances = get_instances_from_report(os.path.join(args.reports_dir, 'steghide.csv'))
outguess_instances = get_instances_from_report(os.path.join(args.reports_dir, 'outguess.csv'))
f5_instances = get_instances_from_report(os.path.join(args.reports_dir, 'f5.csv'))
stepic_instances = get_instances_from_report(os.path.join(args.reports_dir, 'stepic.csv'))
lsbsteg_instances = get_instances_from_report(os.path.join(args.reports_dir, 'lsbsteg.csv'))
# for i in clean_png_instances: print(i)
# for i in clean_jpg_instances: print(i)
# for i in steghide_instances: print(i)
# for i in outguess_instances: print(i)
# for i in f5_instances: print(i)
# for i in stepic_instances: print(i)
# for i in lsbsteg_instances: print(i)

# Merge the dirty instances with their respective clean instances.
# Programs that use JPEG:
all_steghide_instances = steghide_instances + clean_jpg_instances
all_outguess_instances = outguess_instances + clean_jpg_instances
all_f5_instances = f5_instances + clean_jpg_instances

# Programs that use PNG:
all_stepic_instances = stepic_instances + clean_png_instances
all_lsbsteg_instances = lsbsteg_instances + clean_png_instances

# Sort the instances by their score.
all_steghide_instances.sort(key=lambda i: i[1], reverse=True)
all_outguess_instances.sort(key=lambda i: i[1], reverse=True)
all_f5_instances      .sort(key=lambda i: i[1], reverse=True)
all_stepic_instances  .sort(key=lambda i: i[1], reverse=True)
all_lsbsteg_instances .sort(key=lambda i: i[1], reverse=True)
# for i in all_steghide_instances: print(i)
# for i in all_outguess_instances: print(i)
# for i in all_f5_instances: print(i)
# for i in all_stepic_instances: print(i)
# for i in all_lsbsteg_instances: print(i)

# Calculate point to plot.
steghide_points = calculate_roc_points(all_steghide_instances)
outguess_points = calculate_roc_points(all_outguess_instances)
f5_points = calculate_roc_points(all_f5_instances)
stepic_points = calculate_roc_points(all_stepic_instances)
lsbsteg_points = calculate_roc_points(all_lsbsteg_instances)

# Calculate the points for a discrete classifier of threshold 0.2.
threshold = 0.005
steghide_discrete_point = calculate_discrete_classifier_point(all_steghide_instances, threshold)
outguess_discrete_point = calculate_discrete_classifier_point(all_outguess_instances, threshold)
f5_discrete_point = calculate_discrete_classifier_point(all_f5_instances, threshold)
stepic_discrete_point = calculate_discrete_classifier_point(all_stepic_instances, threshold)
lsbsteg_discrete_point = calculate_discrete_classifier_point(all_lsbsteg_instances, threshold)
# print("steghide_discrete_point:", steghide_discrete_point)
# print("outguess_discrete_point:", outguess_discrete_point)
# print("f5_discrete_point:", f5_discrete_point)
# print("stepic_discrete_point:", stepic_discrete_point)
# print("lsbsteg_discrete_point:", lsbsteg_discrete_point)


# Plot all of them on a single graph.
# Create lists with x and y coordinates.
lsbsteg_xs = list(map(lambda p: p[0], lsbsteg_points))
lsbsteg_ys = list(map(lambda p: p[1], lsbsteg_points))
stepic_xs = list(map(lambda p: p[0], stepic_points))
stepic_ys = list(map(lambda p: p[1], stepic_points))
steghide_xs = list(map(lambda p: p[0], steghide_points))
steghide_ys = list(map(lambda p: p[1], steghide_points))
outguess_xs = list(map(lambda p: p[0], outguess_points))
outguess_ys = list(map(lambda p: p[1], outguess_points))
f5_xs = list(map(lambda p: p[0], f5_points))
f5_ys = list(map(lambda p: p[1], f5_points))

# These are the AUCs
f5_auc = np.trapz(f5_ys,f5_xs)
steghide_auc = np.trapz(steghide_ys,steghide_xs)
outguess_auc = np.trapz(outguess_ys,outguess_xs)
stepic_auc = np.trapz(stepic_ys,stepic_xs)
lsbsteg_auc = np.trapz(lsbsteg_ys,lsbsteg_xs)

# Plot the ROC curves.
plt.plot(steghide_xs, steghide_ys, lw=2, color='Red', label='Steghide (AUC = %0.2f)' % steghide_auc)
plt.plot(outguess_xs, outguess_ys, lw=2, color='Yellow', label='Outguess (AUC = %0.2f)' % outguess_auc)
plt.plot(f5_xs,       f5_ys,       lw=2, color='Brown', label='F5 (AUC = %0.2f)' % f5_auc)
plt.plot(stepic_xs,   stepic_ys,   lw=2, color='Green', label='Stepic (AUC = %0.2f)' % stepic_auc)
plt.plot(lsbsteg_xs,  lsbsteg_ys,  lw=2, color='Blue', label='LSBSteg (AUC = %0.2f)' % lsbsteg_auc)

# Plot the discrete classifiers.
plt.plot(steghide_discrete_point[0], steghide_discrete_point[1], 'o', markersize=10, color='Red')
plt.plot(outguess_discrete_point[0], outguess_discrete_point[1], 'o', markersize=10, color='Yellow')
plt.plot(f5_discrete_point[0], f5_discrete_point[1],             'o', markersize=10, color='Brown')
plt.plot(stepic_discrete_point[0], stepic_discrete_point[1],     'o', markersize=10, color='Green')
plt.plot(lsbsteg_discrete_point[0], lsbsteg_discrete_point[1],   'o', markersize=10, color='Blue')

# Plot the diagonal.
plt.plot([0,1], [0,1], color="black", ls='--', lw=0.5)

# Write title, labels, legends and all to the figure.
# plt.title(title)
plt.xlabel("Taxa de Positivos Falsos")
plt.ylabel("Taxa de Positivos Verdadeiros")
plt.legend(loc="lower right")
plt.axis([0, 1, 0, 1])
plt.grid(True)

# Save or show figure.
plt.savefig('rocs.png', bbox_inches='tight')
# plt.show()
