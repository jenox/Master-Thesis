# Motivation

Input graph -> cluster -> cluster graph -> magic -> map/cartogram
All in a dynamic setting! Input graph can change: insert/remove edges/vertices -> clustering changes -> map changes!

Idea
- Contact representation of clusters (according to vertex and edge weights in cluster graph)
- Resize cluster according to cluster size
- Embed actual graph on top of map/contact representation

Goals
- cluster area proportional to vertex weight / cluster size
- common boundary of two countries/clusters proportional to edge weight
- locally fat regions such that we can properly embed original graph on top

High level
- Clustering (with directed loop) -> Planar Embedding -> Cartogram
- For now, focus on the latter, assume rest is given.

Lower level
- Weighted cluster graph -> any contact representation -> statistically accurate contact representation
- Any dynamic update (e.g. cluster weight changes) circles back to any contact representation
- For now, assume we have weighted planar embedding

How to get statistically accurate contact representation?
- For now: diffusion algorithm (hopefully yields organic structures)
- Alternatives
    - air pressure cartograms
    - rubber sheet methods
    - force-directed approaches with Impred (preserves edge-crossing properties)
