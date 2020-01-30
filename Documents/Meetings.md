__Since last meeting__

**Algorithm:** make contact representation  
**Input:** planar straight-line drawing of 2-connected, internally triangulated graph G  
**Output:** 1-subdivision of "dual" contact representation

- create empty dual graph  
- for `f` in G.innerFaces:  
    - add "face" vertex `f` at barycenter of `f`  
- for `{u,v}` in G.edges:  
    - if `{u,v}` adjacent to 2 faces `f ≠ g`:  
        - add subdivion vertex `x` at midpoint of `{u,v}`  
        - add edge between `f` and `x`  
        - add edge between `x` and `g`  
    - elseif `{u,v}` adjacent to single face `f`:  
        - add "outer edge" vertex `{u,v}` at midpoint of `{u,v}`  
        - add subdivion vertex `x` at midpoint of midpoint of `{u,v}` and barycenter of `f`  
        - add edge between `{u,v}` and `x`  
        - add edge between `x` and `f`  
- for `({u,v}, {v,w})` in incident edges of G.outerFace:  
    - add subdivion vertex `x` at position of `v`  
    - add edge between `{u,v}` and `x`  
    - add edge between `x` and `{v,w}`  


__2020-01-30__

- More algorithm drafting / implementation

TODOs:
- Rename "Embedding" phase to "Filtering + Embedding"
- Send algorithm in pseudocode to Tamara
- Torsten: graphs of degree 3 are area-universal (Thomasson)
    - Max degree? Outer face might not have deg 3. We could augment and remove though!
- Force-directed algorithm
    - Push vertices towards bisector of the two adjacent edges in face
    - Weight different vertex displacements: based on local fatness
        - If adjacent to two faces: want 180deg angle
        - If adjacent to three faces: want 120deg angle
    - Prevent edge crossings!
- Up next: bigger test instances, dynamics
- Next meetings on Feb 13th and Feb 27th


__2020-01-16__

- Algorithm and evaluation structure
- Draft input graph -> graph on which we run force-directed layout transformation
- Title: Visualizing dynamic clustered data using area-proportional maps

![](pipeline.jpg "Algorithm & Evaluation Pipeline")


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
- Linda Kleist result as initial configuration for force-directed?
- Check if Webcola can be used to ensure no edge crossings are created! -> no
- Draft algorithm and evaluation structure: black boxes with input and output
- Title for thesis
- Quality Metrics
    - “Local fatness”
    - Polygonal complexity
    - Can we create constraints for those?
- Research questions for evaluation?
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

