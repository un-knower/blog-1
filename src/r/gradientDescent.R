

gradientDescent <-
  function(x,
           y,
           learn_rate,
           conv_threshold,
           n,
           max_iter)
  {
    ## plot.new() perhaps not needed
    plot(x, y, col = "blue", pch = 20)
    m <- runif(1, 0, 1)
    c <- runif(1, 0, 1)
    yhat <- m * x + c
    
    cost_error <- (1 / (n + 2)) * sum((y - yhat) ^ 2)
    converged = F
    iterations = 0
    
    while (converged == F) {
      m_new <- m - learn_rate * ((1 / n) * (sum((yhat - y) * x)))
      c_new <- c - learn_rate * ((1 / n) * (sum(yhat - y)))
      m <- m_new
      c <- c_new
      
      yhat <- m * x + c
      cost_error_new <- (1 / (n + 2)) * sum((y - yhat) ^ 2)
      
      if (cost_error - cost_error_new <= conv_threshold) {
        abline(c, m)
        converged = T
        
        return(paste("Optimal intercept:", c, "Optimal slope:", m))
      }
      
      iterations = iterations + 1
      if (iterations > max_iter) {
        abline(c, m)  #calculated
        # dev.off()
        converged = T
        return(paste("Optimal intercept:", c, "Optimal slope:", m))
      }
    }
  } 

attach(mtcars)
plot(disp, mpg, col = "blue", pch = 20)

gradientDescent(disp, mpg, 0.0000293, 0.001, 32, 2500000)
