library(jsonlite)
library(networkD3)

nodes <-
  jsonlite::stream_in(file(
    "F:/datacenter/data/knowledgeGraph/listedCompany/nodes.json"
  ))

edges_df <-
  jsonlite::stream_in(file(
    "F:/datacenter/data/knowledgeGraph/listedCompany/edge.json"
  ))

head(nodes)
head(edges_df)

# simpleNetwork(edges_df[c("from", "to")])
library(igraph)
g2 = graph.data.frame(d = edges_df[c("from", "to")], directed = F)

V(g2) #查看顶点
E(g2)

#plot(g2,layout=layout.fruchterman.reingold,vertex.label=NA)
plot(
  g2,
  layout = layout.fruchterman.reingold,
  vertex.size = 2,
  vertex.color = "red",
  edge.arrow.size = 0.05,
  vertex.label = NA
)

com = walktrap.community(g2, steps = 10)
V(g2)$sg = com$membership
V(g2)$color = rainbow(max(V(g2)$sg), alpha = 0.8)[V(g2)$sg]

plot(
  g2,
  layout = layout.fruchterman.reingold,
  vertex.size = 1,
  vertex.color = V(g2)$color,
  edge.width = 0.4,
  edge.arrow.size = 0.08,
  edge.color = rgb(1, 1, 1, 0.4),
  vertex.frame.color = NA,
  margin = rep(0, 4),
  vertex.label = NA
)


E(g1)$color = V(g1)[name = ends(g1, E(g1))[, 2]]$color #为edge的颜色赋值

V(g1)[grep("李军", V(g1)$name)]$color = rgb(1, 1, 1, 0.8) #为vertex的颜色赋值

plot(
  g1,
  layout = layout.fruchterman.reingold,
  vertex.size = V(g1)$size,
  vertex.color = V(g1)$color,
  edge.width = 0.3,
  edge.color = E(g1)$color,
  vertex.frame.color = NA,
  margin = rep(0, 4),
  vertex.label = NA
)