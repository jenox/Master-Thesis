- Because our polygons have low number of vertices, edges are relatively long and we place a lot of subdivision vertices on there, resulting in 180deg angles dominating heavily!

__2020-03-26__

- Randomly generate vertex-weighted graphs
    - Parameters
        - bounds
        - range of weights
        - number of vertices
        - fraction of vertices nested into existing triangles
        - nesting bias
    - Problem: "unnatural" shapes
        - Triangulation creates tight countries on outside
        - Cramped initial layout: Minimum distance between points? ~~Distribute points evenly?~~ Run force-directed algorithm before applying transformation?
- Implement entropy-based quality metrics
    - Numbers don't currently appear meaningful
    - Complexity measure was intended for point clouds, we diverted it from its original use: add more points on polygon boundary to get closer to original use, e.g. subdivide edges while length ≥ epsilon?
- Edge flips can create multiple adjacencies, e.g. A-E in small graph!

TODOs:
- [ ] Draw generated, untransformed, vertex-weighted graphs
- [ ] Minimum distance when generating graphs, maybe run force-directed before transforming?
- [ ] Forbidden edges for edge flips
- [x] Improve entropy measures by getting similar edge lengths first
- [ ] Start writing :)

- For Evaluation:
    - Just for visualization: beziers for edges, subdivision vertices as control points
    - Look at "degrees" of countries when presenting results, "graph diameter"
    - Number of points in convex hull
    - "Will need user study to see if metrics correspond to human perception"

__2020-03-19__

- Local Fatness
    - Estimating complexity of 2D shapes
        - length of shortest turing machine that outputs polygon
        - deals with (unordered) points, not necessarily polygons
        - distribution/entropy of distances from centroid
        - distribution/entropy of angles at points (they "guess" connections)
        - random trace through points: not relevant to us, we know how points are connected
    - Better Bounds on the Union Complexity of Locally Fat Objects
        - k-fatness: minimum ratio of area of circle with boundary intersecting and center inside polygon intersecting polygon to circle area
        - susceptible to small angles
    - Measuring the Complexity of Polygonal Objects:
        - distance from convex hull
        - amplitude and frequency of vibration
    - Guarding Fat Polygons and Triangulating Guarded Polygon
        - epsilon good: every point can see at least an epsilon-fraction of the polygon area (or boundary)
        - (alpha, beta)-covered: for every point on boundary we can fit a triangle with angle ≥ alpha and sides ≥ beta inside the polygon
        - susceptible to small angles
- Forces
    - Force debugging and visualization tool
    - Stability issues: vertex-vertex-repulsion grows the map infinitely, angle seems to shrink it
    - Some force "configurations" work well for the bigger test case but not so well for the small on -> need randomized test cases!
- Test case generation

Gravitation center for forces?

"Local" fatness metrics:
- [x] "Distance" from circumcircle
- [x] "Distance" from convex hull
- [x] Entropy of angles
- [x] Entropy of distances from centroid

TODOs:
- [x] Implement different quality metrics
- [x] Test cases for real this time


__2020-03-13__

- Crossing are created due to floating point inaccuracies (?) when vertices are too close to one another!
- Short borders after edge flip -> Repelling forces between vertices of degree 3?

TODOs:
- [x] Do some research on _local_ fatness in literature: Computational geometry @ Utrecht, Maarten Loeffler, Bettina Speackman
    - Or existence k-kernel of polygon as additional metric? -> Punish snakes
    - CGAL library
- [ ] Implement test case generation
    - Different graph sizes, up to 30 countries
    - When nesting K4s, prefer triangles that were already nested into others
- [x] Improve forces
    - Forces repelling degree-3-vertices
    - Forces working towards (local) fatness
    - Forces working against tight corridors


__2020-03-05__

- Focus on better initial layout (Kleist/Thomassen) only if we have time!

TODOs:
- [x] Try merging vertices when they get too close to one another
    - Only contract edges; but not edges between 2 3-degree verices
- [x] Implement other dynamic operations with additional subdivision vertices
    - Implemented generic internal edge flip
- [x] Implement quality metrics: statistical accuracy, local fatness
    - Implemented: polygon area / area of regular n-gon in smalltest enclosing circle (though more "global"?)
    - Other idea 1: [incircle / circumcircle](https://mathematica.stackexchange.com/questions/121987/how-to-find-the-incircle-and-circumcircle-for-an-irregular-polygon)
    - Other idea 2: area of the smallest circle of the largest circles fitting on the inside of polygon, touching two adjacent segments
        - Unnormalized. What about vertices with internal angle >180deg?
    - Problems with some ideas: infinitesimal tweaks should have infinitesimal impact on fatness
- [x] Think about test case generation
    - Voronoi/Delaunay triangulation on random points, random weights?
    - Nest K4s in random triangles?
    - In regular intervals, perform random dynamic operations: change weights randomly, flip random internal border?


__2020-02-13__

- Transformation algorithm in pseudocode
- Problem with initial force-directed implementation
    - Subdivision vertices are very rigid and severly restrict movement of other vertices
    - Tight corridors are being generated
    - Edge crossings are still being generated

TODOs:
- [x] Try to balance distance between subdivision vertices and their neighbors
- [ ] Try adding repulsive forces between vertices and edges of the same face -> local fatness
- [x] Fix PrEd implementation
    - Works, but is pretty slow now!
- [ ] Try speeding things up by only adding helper vertices after a couple of iterations
    - Would require different transformation as current implementation relies on subdivision vertices to be valid contact representation
- [ ] Theory and practice together: start with optimal drawing already (Kleist/Thomassen)
    - Would be inconsistent with how we apply dynamic updates though!
- [x] Read Circular Arc Kobourov Cartogram: one-bend to circular arc?
    - No dummy vertices, flow network problem
- [x] Reread Lombardi Spring Embedder: also with one-bend helper vertex?
    - Dummy vertex added only in second phase, and _only those_ are displaced in second force-directed phase
- [x] Read Thomassen paper


__2020-01-30__

- More algorithm drafting / implementation

TODOs:
- [x] Rename "Embedding" phase to "Filtering + Embedding"
- [x] Send algorithm in pseudocode to Tamara
- [ ] Torsten: graphs of degree 3 are area-universal (Thomassen)
    - Max degree? Outer face might not have degree 3. We could augment and remove though!
- [x] Force-directed algorithm
    - Push vertices towards bisector of the two adjacent edges in face
    - Weight different vertex displacements: based on local fatness
        - If adjacent to two faces: want 180deg angle
        - If adjacent to three faces: want 120deg angle
    - Prevent edge crossings!
- Up next: bigger test instances, dynamics


__2020-01-16__

- Algorithm and evaluation structure
- Draft input graph -> graph on which we run force-directed layout transformation
- Title: Visualizing dynamic clustered data using area-proportional maps

![](pipeline.jpg "Algorithm & Evaluation Pipeline")

Changes:
- "Embedding" -> "Filtering + Embedding"


__2020-01-09__

Drawing planar 3-trees with given face areas
- straight line edges only
- recursive construction based on barycentric coordinates in K4

Drawing graphs with prescribed face faces
- edges with 1 bend
- uses air pressure algorithms internally
- not organic-looking at all
- difficult to adapt to dynamic setting

On rectilinear duals for vertex-weighted Plane graphs
- definition rectangular/rectilinear dual
- theoretical results on complexity of cartogram

Planar graphs and face areas: area universality
- area universal graphs: straight line drawing exists for arbitrary face areas
- Duality of problems: cartogram for vertex-weighted graph vs realizing drawing (of dual) with given face areas

TODOs
- [x] Can Linda Kleist result as initial configuration for force-directed?
- [x] Check if Webcola can be used to ensure no edge crossings are created! -> no
- [x] Draft algorithm and evaluation structure: black boxes with input and output
- [x] Title for thesis
- [x] Think about quality metrics
    - “Local fatness”
    - Polygonal complexity
    - Can we create constraints for those?
- [x] Think about research questions for evaluation
    - How much worse is applying changes to just starting from scratch?
    - Think in terms of possible plots

![](dual-construction.jpg "Dual construction")

https://ialab.it.monash.edu/~dwyer/
http://www.adaptagrams.org
https://ialab.it.monash.edu/webcola/


__2019-12-19__

Explored diffusion algorithm for cartograms (M. Newman)
- Plain old C, input is density matrix and output maps cells to a new position where they would diffuse to
- Took some time to get it running and to visualize the data
- Smooth animations from initial layout to converged state possible -> Demo
- Limitations
    - Not 100% statistically accurate
    - Works with fixed-size matrix of initial densities, inserting new countries might be hard
    - Hard/impossible to adapt to account for edge weights

Started writing down conventions & co.


__2019-12-12__

No meeting: Tamara’s son sick


__2019-12-05__

No meeting: Tamara away


__2019-11-28__

We should be able to achieve perfectly statistically accurate cartograms
- Can’t have all three of perfect statistical, geographic and topological accuracy
- We don’t care about geographic accuracy because we don’t have a true underlying geographic map!

Framework
- Weighted cluster graph -> any contact representation -> statistically accurate contact representation
    - Repeat last step after dynamic update
    - How to get initial map / contact representation?
        - ~~Circle packing?~~
        - Orthogonal polygons?
        - Shift/Schnyder + Impred + “Dual”?
    - Which algorithm to use to generate statistically accurate contact representation / cartogram?
        - For now: diffusion algorithm
- Goals for resulting map
    - Organic
    - Locally fat regions
- Exploration of permitted operations on cluster graph
    - no rivers/lakes -> internally triangulated cluster graph
    - vertex removal
    - vertex insertion

How to visualize edge weights?
- As length of common boundary of two countries

Until next meeting: start coding and getting a feel for things


__2019-11-21__

No meeting: Tamara away


__2019-11-14__

Cartograms vs graph embeddings
- Agreed to drop graph embeddings / ML direction and continue with cartograms

New directions to explore for generating cartograms
- Air-pressure cartograms
- Gosper Map (D. Auber)

Dynamic operations on cluster graph
- New vertices
- Edges appear or disappear while keeping embedding stable
- Weights on vertices and/or edges change

Until next meeting: more research on cartograms


__2019-11-07__

No meeting: Tamara sick


__2019-10-31__

No meeting: Christian sick

