# Configuração de formatação
.cfg <- new.env()
.cfg$decimals <- 3
.cfg$digits <- 7

configurar_saida <- function(decimals = 3, digits = 7) {
  .cfg$decimals <- decimals
  .cfg$digits <- digits
}

# Formata números com sprintf
# Funciona com escalar, vetor ou matriz (devolve sempre um vetor de textos)
fmt_num <- function(x) {
  d <- .cfg$decimals
  x[abs(x) < 0.5 * 10^(-d)] <- 0 # evita imprimir "-0.000"
  sprintf(paste0("%", .cfg$digits, ".", d, "f"), x)
}

# Imprime o tableau completo, com cabeçalho e nome das variáveis
imprimir_tableau <- function(tab, nomes, titulo = NULL) {
  m <- tab$m
  n <- tab$n
  
  cel <- matrix(fmt_num(tab$mat), nrow(tab$mat)) # Números como texto
  cab <- c(paste0("y", seq_len(m) - 1), nomes, "b") # Cabeçalho das colunas
  rot <- c("z", nomes[tab$base]) # Rótulo de cada linha
  
  w <- max(nchar(cab), nchar(cel)) # Largura única para todas as colunas
  wr <- max(nchar(rot)) # Largura da coluna de rótulos
  
  linha <- function(rotulo, itens) {
    itens <- formatC(itens, width = w)
    paste(
      formatC(rotulo, width = wr, flag = "-"),
      "|", paste(itens[1:m], collapse = " "),
      "|", paste(itens[(m + 1):(m + n)], collapse = " "),
      "|", itens[m + n + 1]
    )
  }
  
  cabecalho <- linha("", cab)
  traco <- strrep("-", nchar(cabecalho))
  
  if (!is.null(titulo)) cat("\n", titulo, "\n", sep = "")
  cat(cabecalho, "\n", traco, "\n", sep = "")
  for (r in seq_len(nrow(cel))) {
    cat(linha(rot[r], cel[r, ]), "\n", sep = "")
    if (r == 1) cat(traco, "\n", sep = "")
  }
}

# Descreve o pivô que está para acontecer. Chamar antes de pivotear()
imprimir_pivo <- function(tab, nomes, l, j) {
  cat(sprintf("Pivô: entra %s, sai %s\n", nomes[j], nomes[tab$base[l]]))
}

imprimir_vetor <- function(x) {
  cat(paste(fmt_num(x), collapse = " "), "\n", sep = "")
}

imprimir_fpi <- function(fpi) {
  cat("\n=== PL na forma padrão de igualdade (FPI) ===\n")
  M <- rbind(c(fpi$obj, 0), cbind(fpi$A, fpi$b))
  cel <- matrix(fmt_num(M), nrow = nrow(M))
  cel[1, ncol(cel)] <- ""                       
  cab <- c(fpi$nomes, "b")
  w <- max(nchar(cab), nchar(cel))
  linha <- function(rotulo, itens) {
    itens <- formatC(itens, width = w)
    paste(formatC(rotulo, width = -4), "|",
          paste(itens[-length(itens)], collapse = " "), "|", itens[length(itens)])
  }
  cabecalho <- linha("", cab)
  cat(cabecalho, "\n", strrep("-", nchar(cabecalho)), "\n", sep = "")
  cat(linha("max", cel[1, ]), "\n", sep = "")
  for (i in seq_len(nrow(fpi$A))) cat(linha("", cel[i + 1, ]), "\n", sep = "")
}

imprimir_inviavel <- function() cat("\nStatus: inviável\n")
imprimir_ilimitado <- function() cat("\nStatus: ilimitado\n")

imprimir_otimo <- function(z, x, dual, x2 = NULL) {
  cat(if (is.null(x2)) "\nStatus: ótimo\n" else "\nStatus: ótimo (múltiplos)\n")
  cat("Objetivo: ", fmt_num(z), "\n", sep = "")
  if (is.null(x2)) {
    cat("Solução:\n");  imprimir_vetor(x)
  } else {
    cat("Soluções:\n"); imprimir_vetor(x); imprimir_vetor(x2)
  }
  cat("Dual:\n")
  imprimir_vetor(dual)
}