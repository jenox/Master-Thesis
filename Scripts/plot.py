# coding=utf8

import os
import pandas
import seaborn
from matplotlib import pyplot

pwd = os.path.dirname(os.path.realpath(__file__))
inputdir = "{0}/../Evaluation/metrics".format(pwd)
outputdir = "{0}/../Evaluation/plots".format(pwd)
if not os.path.exists("{0}/".format(outputdir)):
    os.makedirs("{0}/".format(outputdir))

inputfilenames = [
    "10-0.0-0.0", "10-0.25-0.0", "10-0.25-0.5", "10-0.25-0.99", "10-0.5-0.0", "10-0.5-0.5", "10-0.5-0.99",
    "15-0.0-0.0", "15-0.25-0.0", "15-0.25-0.5", "15-0.25-0.99", "15-0.5-0.0", "15-0.5-0.5", "15-0.5-0.99",
    "20-0.0-0.0", "20-0.25-0.0", "20-0.25-0.5", "20-0.25-0.99", "20-0.5-0.0", "20-0.5-0.5", "20-0.5-0.99",
    "25-0.0-0.0", "25-0.25-0.0", "25-0.25-0.5", "25-0.25-0.99", "25-0.5-0.0", "25-0.5-0.5", "25-0.5-0.99",
    "30-0.0-0.0", "30-0.25-0.0", "30-0.25-0.5", "30-0.25-0.99", "30-0.5-0.0", "30-0.5-0.5", "30-0.5-0.99",
]
frames = map(lambda x: pandas.read_csv("{0}/{1}.csv".format(inputdir, x)), inputfilenames)
data = pandas.concat(frames)
data["nesting ratio and bias"] = "(" + data["nesting ratio"].astype(str) + ", " + data["nesting bias"].astype(str) + ")"

sizes = [10, 15, 20, 25, 30]
nestings = [(0.0, 0.0), (0.25, 0.0), (0.25, 0.5), (0.25, 0.99), (0.5, 0.0), (0.5, 0.5), (0.5, 0.99)]
times = [0, 2, 4, 6, 10, 20]

metrics = [
    ("maximum cartographic error", "MaximumCartographicError"),
    ("average cartographic error", "AverageCartographicError"),
    ("maximum polygon complexity", "MaximumPolygonComplexity"),
    ("average polygon complexity", "AveragePolygonComplexity"),
]

seaborn.set(rc = { 'figure.figsize': (8, 6) })

print("Creating plots for variable number of operations…")
for n in sizes:
    for (a, b) in nestings:
        suffix = "t=?,n={0},a={1},b={2}".format(n, a, b)
        filtered = data[data["number of vertices"].eq(n) & data["nesting ratio"].eq(a) & data["nesting bias"].eq(b) & data["number of operations"].isin(times)]
        for (column, prefix) in metrics:
            pyplot.clf()
            seaborn.swarmplot(y=column, x="number of operations", data=filtered).get_figure().savefig("{0}/{1}-{2}.pdf".format(outputdir, prefix, suffix))

print("Creating plots for variable nesting ratio and bias…")
for n in sizes:
    for t in times:
        suffix = "a=?,b=?,n={0},t={1}".format(n, t)
        filtered = data[data["number of vertices"].eq(n) & data["number of operations"].eq(t)]
        for (column, prefix) in metrics:
            pyplot.clf()
            seaborn.swarmplot(y=column, x="nesting ratio and bias", data=filtered).get_figure().savefig("{0}/{1}-{2}.pdf".format(outputdir, prefix, suffix))

print("Creating plots for variable number of vertices…")
for (a, b) in nestings:
    for t in times:
        suffix = "n=?,a={0},b={0},t={2}".format(a, b, t)
        filtered = data[data["nesting ratio"].eq(a) & data["nesting bias"].eq(b) & data["number of operations"].eq(t)]
        for (column, prefix) in metrics:
            pyplot.clf()
            seaborn.swarmplot(y=column, x="number of vertices", data=filtered).get_figure().savefig("{0}/{1}-{2}.pdf".format(outputdir, prefix, suffix))
