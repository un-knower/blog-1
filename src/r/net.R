nodes <- data.frame(id = 1:18, label = paste("n", 1:18))
from <-
  c(12, 9, 5, 10, 1, 17, 14, 6, 13, 4, 10, 10, 14, 11, 12, 7, 4, 1, 15, 10)
to <-
  c(9, 5, 10, 1, 17, 14, 7, 2, 1, 8, 16, 3, 4, 18, 4, 4, 11, 4, 2, 6)
edges <-
  data.frame(
    from,
    to,
    arrows = c("to", "from", "middle", "middle;to"),
    # smooth
    smooth = c(FALSE, TRUE),
    # shadow
    shadow = c(FALSE, TRUE, FALSE, TRUE),
    label = paste("e", 1:20)
  )

# library(igraph)
# net <- graph.data.frame(edges, nodes, directed = T)
# plot(net, layout = layout_with_fr(net))

# install.packages("visNetwork")
#library('visNetwork')
require(visNetwork, quietly = TRUE)
visNetwork(nodes,
           edges,
           height = "1000px",
           width = "100%",
           main = "Network!")