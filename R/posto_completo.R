# Remove linhas linearmente dependentes de A (FPI)
# Devolve list(fpi = fpi_reduzida, inviavel = TRUE/FALSE)

# Funciona como uma eliminação de Gauss feito linha a linha.
remover_dependentes <- function(fpi, verbose = TRUE) {
  m <- fpi$m
  n <- fpi$n_fpi
  
  reduzidas <- list() # linhas mantidas, já reduzidas e normalizadas
  pivos <- integer(0) # coluna pivô de cada linha mantida
  mantidas <- integer(0) # índices (na FPI) das linhas mantidas
  
  for (i in seq_len(m)) {
    v <- c(fpi$A[i, ], fpi$b[i]) 
    tol <- 1e-9 * max(1, abs(v))
    
    for (k in seq_along(mantidas)) {
      v <- v - v[pivos[k]] * reduzidas[[k]]
    }
    
    if (max(abs(v[1:n])) > tol) {
      # Linha independente
      pc <- which.max(abs(v[1:n]))
      reduzidas[[length(reduzidas) + 1]] <- v / v[pc]
      pivos <- c(pivos, pc)
      mantidas <- c(mantidas, i)
    } else if (abs(v[n + 1]) > tol) {
      return(list(fpi = fpi, inviavel = TRUE))
    } else if (verbose) {
      cat(sprintf("Restrição %d e redundante e foi removida.\n", i - 1))
    }
  }
  
  fpi$A <- fpi$A[mantidas, , drop = FALSE]
  fpi$b <- fpi$b[mantidas]
  fpi$m <- length(mantidas)
  fpi$linhas_mantidas <- mantidas
  list(fpi = fpi, inviavel = FALSE)
}