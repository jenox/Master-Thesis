# Dynamic Operations
- Change weights
    - Trivial
- Add Vertex
    - Inside: in exisiting triangle with respective adjacencies
    - Outside: with adjacencies to ≥2 clusters on the outside that lie on a path
- Remove Vertex
- Add Edge
    - Can only add edges on the outside: between two non-adjacent clusters that share a neighbor
- Remove Edge
    - Internal edges can never be removed (must preserve internal triangulation)
    - Only some external edges can be removed (must preserve 2-connectedness)
- Flip Edge
    - Only internal edges (incident to two clusters) can be flipped


- add vertex inside (in triangle)
    - easy
- add vertex outside, adjacent to 2 adjacent clusters
    - probably easy
- add vertex outside, adjacent to more than 2 clusters lying on a path
    - ?
- remove vertex inside triangle
    - easy
- remove vertex outside, adjacent to 2 adjacent clusters
    - wo DO lose degrees of freedom...
- add/remove external edge (between two non-adjacent clusters that share a neighbor)
    - might not be a straight-line edge!
- flip internal edge
    - problematic
