#!/usr/bin/env python3

from __future__ import absolute_import, division, print_function, unicode_literals
import matplotlib.pyplot as plt
import numpy as np
import argparse
import math
import re
import os

png_programs = ['stepic', 'lsbsteg']
jpg_programs = ['f5', 'steghide', 'outguess']
programs = png_programs + jpg_programs

# Describe arguments and options.
parser = argparse.ArgumentParser(description='Create ROC curves for each steganalitic method, targeting a specific steganography program.')
parser.add_argument("reports_dir", help="Path to the StegExpose reports.")
parser.add_argument("program", choices=programs)
parser.add_argument("-n", "--name", metavar="graph_name", help="Save the graph with the specified name (it will be a PNG).")

# Parse argumets.
args = parser.parse_args()

def get_data_from_report(report_file_path):
    """
    Parse StegExpose report and return a list of (class, score).
    E.g. [('p', 0.10), ('n', 0.05)]
    """

    datas = []
    with open(report_file_path, 'r') as report_file:
        for line in report_file:
            # Filter the lines without images.
            if re.match(r'.*\.(png|jpg),', line):
                # Get the important data.
                pieces = line.split(sep=',')
                # print(pieces)
                image_name = pieces[0]
                real_class = 'p' if re.match(r'.*_\d+p\.(png|jpg),', line) else 'n'
                above_threshold = pieces[1] == 'true'
                message_size = int(pieces[2])
                primary_sets_score = float(pieces[3])
                chi_square_score = float(pieces[4])
                sample_pairs_score = float(pieces[5])
                rs_analysis_score = float(pieces[6])
                fusion_score = float(pieces[7])
                # print(real_class, above_threshold, message_size, primary_sets_score, chi_square_score, sample_pairs_score, rs_analysis_score, fusion_score)
                data = {'real_class': real_class, 'primary_sets_score': primary_sets_score, 'chi_square_score': chi_square_score, 'sample_pairs_score': sample_pairs_score, 'rs_analysis_score': rs_analysis_score, 'fusion_score': fusion_score}
                datas.append(data)
    return datas

def calculate_roc_points(instances):
    """From a sorted list of instances, calculate the points that draw the ROC curve."""

    # Calculate the number of positives and negatives (the real ones).
    P = N = 0
    for label, score in instances:
        # print(label, score)
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
        # print(point)
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

# Parse data out of StegExpose reports.
if args.program in png_programs:
    clean_report_name = 'clean-png.csv'
else:
    clean_report_name = 'clean-jpeg.csv'

program_report_name = args.program + '.csv'
program_data = get_data_from_report(os.path.join(args.reports_dir, program_report_name))
clean_data = get_data_from_report(os.path.join(args.reports_dir, clean_report_name))
# for i in clean_png_instances: print(i)
# for i in instances: print(i)

# Merge clean ones with dirty ones.
merged_data = program_data + clean_data
# for i in merged_data: print(i)

# Create tuples of instances for each steganalytic method
primary_sets_instances = list(map(lambda d: (d['real_class'], d['primary_sets_score']), merged_data))
chi_square_instances = list(map(lambda d: (d['real_class'], d['chi_square_score']), merged_data))
sample_pairs_instances = list(map(lambda d: (d['real_class'], d['sample_pairs_score']), merged_data))
rs_analysis_instances = list(map(lambda d: (d['real_class'], d['rs_analysis_score']), merged_data))
fusion_instances = list(map(lambda d: (d['real_class'], d['fusion_score']), merged_data))
# for i in primary_sets_instances: print(i)


# Sort the instances by their score.
primary_sets_instances.sort(key=lambda i: i[1], reverse=True)
chi_square_instances  .sort(key=lambda i: i[1], reverse=True)
sample_pairs_instances.sort(key=lambda i: i[1], reverse=True)
rs_analysis_instances .sort(key=lambda i: i[1], reverse=True)
fusion_instances      .sort(key=lambda i: i[1], reverse=True)

# Filter instances, removing those that contain 'nan' instead of a score.
filtered_primary_sets_instances = list(filter(lambda t: not math.isnan(t[1]), primary_sets_instances))
filtered_chi_square_instances =   list(filter(lambda t: not math.isnan(t[1]), chi_square_instances))
filtered_sample_pairs_instances = list(filter(lambda t: not math.isnan(t[1]), sample_pairs_instances))
filtered_rs_analysis_instances =  list(filter(lambda t: not math.isnan(t[1]), rs_analysis_instances))
filtered_fusion_instances =       list(filter(lambda t: not math.isnan(t[1]), fusion_instances))
# for i in filtered_primary_sets_instances: print(i)

# Sort once again by their score.
filtered_primary_sets_instances.sort(key=lambda i: i[1], reverse=True)
filtered_chi_square_instances.sort(key=lambda i: i[1], reverse=True)
filtered_sample_pairs_instances.sort(key=lambda i: i[1], reverse=True)
filtered_rs_analysis_instances.sort(key=lambda i: i[1], reverse=True)
filtered_fusion_instances.sort(key=lambda i: i[1], reverse=True)
# for i in filtered_primary_sets_instances: print(i)


# Calculate points to plot.
primary_sets_points = calculate_roc_points(filtered_primary_sets_instances)
chi_square_points = calculate_roc_points(filtered_chi_square_instances)
sample_pairs_points = calculate_roc_points(filtered_sample_pairs_instances)
rs_analysis_points = calculate_roc_points(filtered_rs_analysis_instances)
fusion_points = calculate_roc_points(filtered_fusion_instances)
# for i in primary_sets_points: print(i)

# Plot all of them on a single graph.
# Create lists with x and y coordinates.
primary_sets_xs = list(map(lambda p: p[0], primary_sets_points))
primary_sets_ys = list(map(lambda p: p[1], primary_sets_points))
chi_square_xs = list(map(lambda p: p[0], chi_square_points))
chi_square_ys = list(map(lambda p: p[1], chi_square_points))
sample_pairs_xs = list(map(lambda p: p[0], sample_pairs_points))
sample_pairs_ys = list(map(lambda p: p[1], sample_pairs_points))
rs_analysis_xs = list(map(lambda p: p[0], rs_analysis_points))
rs_analysis_ys = list(map(lambda p: p[1], rs_analysis_points))
fusion_xs = list(map(lambda p: p[0], fusion_points))
fusion_ys = list(map(lambda p: p[1], fusion_points))


# These are the AUCs
primary_sets_auc = np.trapz(primary_sets_ys,primary_sets_xs)
chi_square_auc = np.trapz(chi_square_ys,chi_square_xs)
sample_pairs_auc = np.trapz(sample_pairs_ys,sample_pairs_xs)
rs_analysis_auc = np.trapz(rs_analysis_ys,rs_analysis_xs)
fusion_auc = np.trapz(fusion_ys,fusion_xs)

# Plot the ROC curves.
plt.plot(primary_sets_xs, primary_sets_ys, lw=2, color='Red', label='Primary Sets (AUC = %0.2f)' % primary_sets_auc)
plt.plot(chi_square_xs,   chi_square_ys,   lw=2, color='Yellow', label='Chi Square (AUC = %0.2f)' % chi_square_auc)
plt.plot(sample_pairs_xs, sample_pairs_ys, lw=2, color='Brown', label='Sample Pairs (AUC = %0.2f)' % sample_pairs_auc)
plt.plot(rs_analysis_xs,  rs_analysis_ys,  lw=2, color='Green', label='Rs Analysis (AUC = %0.2f)' % rs_analysis_auc)
plt.plot(fusion_xs,       fusion_ys,       lw=2, color='Blue', label='Fusion (AUC = %0.2f)' % fusion_auc)

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
if args.name:
    plt.savefig(args.name + '.png', bbox_inches='tight')
else:
    plt.show()
