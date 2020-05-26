import pandas as pd
from matplotlib import pyplot as plt
import seaborn as sns

q1 = "maximum cartographic error"
q2 = "average cartographic error"
q3 = "maximum polygon complexity"
q4 = "average polygon complexity"

times = ["t=1","t=3","t=5","t=7","t=11","t=21"]
sizes = ["n=10","n=15","n=20","n=25","n=30"]
complexities = ["a=0.0,b=0.0","a=0.25,b=0.0","a=0.25,b=0.5","a=0.25,b=1.0","a=0.5,b=0.0","a=0.5,b=0.5","a=0.5,b=1.0"]

for size in sizes:
    for complexity in complexities:
        filename = "t=?,{0},{1}".format(size, complexity)
        print(filename)
        df = pd.read_csv("../Evaluation/metrics/{0}.csv".format(filename), index_col=0)
        plt.clf()
        sns.swarmplot(y=q1, x="number of operations", data=df).get_figure().savefig("../Evaluation/figures/ErrorMaximum-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q2, x="number of operations", data=df).get_figure().savefig("../Evaluation/figures/ErrorAverage-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q3, x="number of operations", data=df).get_figure().savefig("../Evaluation/figures/ComplexityMaximum-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q4, x="number of operations", data=df).get_figure().savefig("../Evaluation/figures/ComplexityAverage-{0}.pdf".format(filename))

for size in sizes:
    for time in times:
        filename = "a=?,b=?,{0},{1}".format(size, time)
        print(filename)
        df = pd.read_csv("../Evaluation/metrics/{0}.csv".format(filename), index_col=0)
        plt.clf()
        sns.swarmplot(y=q1, x="nesting ratio and bias", data=df).get_figure().savefig("../Evaluation/figures/ErrorMaximum-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q2, x="nesting ratio and bias", data=df).get_figure().savefig("../Evaluation/figures/ErrorAverage-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q3, x="nesting ratio and bias", data=df).get_figure().savefig("../Evaluation/figures/ComplexityMaximum-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q4, x="nesting ratio and bias", data=df).get_figure().savefig("../Evaluation/figures/ComplexityAverage-{0}.pdf".format(filename))

for complexity in complexities:
    for time in times:
        filename = "n=?,{0},{1}".format(complexity, time)
        print(filename)
        df = pd.read_csv("../Evaluation/metrics/{0}.csv".format(filename), index_col=0)
        plt.clf()
        sns.swarmplot(y=q1, x="number of vertices", data=df).get_figure().savefig("../Evaluation/figures/ErrorMaximum-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q2, x="number of vertices", data=df).get_figure().savefig("../Evaluation/figures/ErrorAverage-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q3, x="number of vertices", data=df).get_figure().savefig("../Evaluation/figures/ComplexityMaximum-{0}.pdf".format(filename))
        plt.clf()
        sns.swarmplot(y=q4, x="number of vertices", data=df).get_figure().savefig("../Evaluation/figures/ComplexityAverage-{0}.pdf".format(filename))
