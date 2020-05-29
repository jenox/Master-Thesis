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

data["initial number of clusters"] = data["number of vertices"]
data["nesting ratio and bias"] = "(" + data["nesting ratio"].transform(str) + ", " + data["nesting bias"].transform(str) + ")"

metrics = [
    ("maximum cartographic error", "MaximumCartographicError"),
    ("average cartographic error", "AverageCartographicError"),
    ("maximum polygon complexity", "MaximumPolygonComplexity"),
    ("average polygon complexity", "AveragePolygonComplexity"),
]

seaborn.set(rc = { "figure.figsize": (7, 5.25) })

print("Creating plots for variable number of operations…")
for n in [20]:
    for (a, b) in [(0,0)]:
        suffix = "t=?,n={0},a={1},b={2}".format(n, a, b)
        for (column, prefix) in metrics:
            if column.find("error") != -1:
                filtered = data[data["initial number of clusters"].eq(n) & data["nesting ratio"].eq(a) & data["nesting bias"].eq(b) & data["number of operations"].isin([0,1,2,5,10,20])]
                pyplot.clf()
                chart = seaborn.swarmplot(y=column, x="number of operations", data=filtered, size=4.375)
                chart.get_figure().savefig("{0}/{1}-{2}.pdf".format(outputdir, prefix, suffix), bbox_inches="tight", pad_inches=0)
            else:
                filtered = data[data["initial number of clusters"].eq(n) & data["nesting ratio"].eq(a) & data["nesting bias"].eq(b) & data["number of operations"].isin([0,4,8,12,16,20])]
                pyplot.clf()
                chart = seaborn.swarmplot(y=column, x="number of operations", data=filtered, size=4.375)
                chart.get_figure().savefig("{0}/{1}-{2}.pdf".format(outputdir, prefix, suffix), bbox_inches="tight", pad_inches=0)

print("Creating plots for variable nesting ratio and bias…")
for n in [20]:
    for t in [0]:
        suffix = "a=?,b=?,n={0},t={1}".format(n, t)
        filtered = data[data["initial number of clusters"].eq(n) & data["number of operations"].eq(t)]
        for (column, prefix) in metrics:
            pyplot.clf()
            chart = seaborn.swarmplot(y=column, x="nesting ratio and bias", data=filtered, size=4.375)
            chart.get_figure().savefig("{0}/{1}-{2}.pdf".format(outputdir, prefix, suffix), bbox_inches="tight", pad_inches=0)

print("Creating plots for variable number of vertices…")
for (a, b) in [(0,0)]:
    for t in [0]:
        suffix = "n=?,a={0},b={1},t={2}".format(a, b, t)
        filtered = data[data["nesting ratio"].eq(a) & data["nesting bias"].eq(b) & data["number of operations"].eq(t)]
        for (column, prefix) in metrics:
            pyplot.clf()
            chart = seaborn.swarmplot(y=column, x="initial number of clusters", data=filtered, size=4.375)
            chart.get_figure().savefig("{0}/{1}-{2}.pdf".format(outputdir, prefix, suffix), bbox_inches="tight", pad_inches=0)
