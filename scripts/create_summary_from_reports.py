#!/usr/bin/env python3

from __future__ import absolute_import, division, print_function, unicode_literals
import argparse
import re
import os

# Describe arguments and options.
parser = argparse.ArgumentParser(description='Create ROC curves based on StegExpose reports.')
parser.add_argument("reports_dir", help="Path to the StegExpose reports.")
parser.add_argument("-t", "--threshold", metavar="threshold", type=float, default=0.2,
                    help="Threshold that will be used to create the binary classification.")

# Parse argumets.
args = parser.parse_args()

# print(args.reports_dir)
# print(args.threshold)

def process_report(report_path, threshold=0.2):
    summary = {0: 0, 10: 0, 20: 0, 30: 0, 40: 0, 50: 0, 60: 0, 70: 0, 80: 0, 90: 0, 100: 0}
    with open(report_path, 'r') as report_file:
        for line in report_file:
            # Filter out the lines without images.
            if re.match(r'.*\.(png|jpg),', line):
                pieces = line.split(sep=',')
                # print(pieces)
                image_name = pieces[0]
                image_score = pieces[-1]
                percentage_search = re.search(r'_(\d+)p\.', image_name)
                if percentage_search:
                    percentage = int(percentage_search.group(1))
                else:
                    percentage = 0
                score = float(image_score)
                is_stego = score >= threshold

                # Add to the summary if it was classified as stego.
                if is_stego:
                    summary[percentage] += 1
                # print(percentage, score, is_stego)
    return summary


clean_png_summary = process_report(os.path.join(args.reports_dir, 'clean-png.csv'), args.threshold)
clean_jpeg_summary = process_report(os.path.join(args.reports_dir, 'clean-jpeg.csv'), args.threshold)
steghide_summary = process_report(os.path.join(args.reports_dir, 'steghide.csv'), args.threshold)
outguess_summary = process_report(os.path.join(args.reports_dir, 'outguess.csv'), args.threshold)
f5_summary = process_report(os.path.join(args.reports_dir, 'f5.csv'), args.threshold)
stepic_summary = process_report(os.path.join(args.reports_dir, 'stepic.csv'), args.threshold)
lsbsteg_summary = process_report(os.path.join(args.reports_dir, 'lsbsteg.csv'), args.threshold)

# Print CSV
print(',F5,Steghide,Outguess,Stepic,LSBSteg')
print('0%,{0},{0},{0},{1},{1}'.format(clean_jpeg_summary[0], clean_png_summary[0]))
for percentage in range(10, 101, 10):
    print('{}%,{},{},{},{},{}'.format(
        percentage,
        f5_summary[percentage],
        steghide_summary[percentage],
        outguess_summary[percentage],
        stepic_summary[percentage],
        lsbsteg_summary[percentage]))

