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
