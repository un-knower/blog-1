x <- seq(1, 50, 0.5)

funGraph <- function(func, x) {
  plot(x, func(x), type = "l")
}

funGraph(log , x)

funGraph(sin , x)