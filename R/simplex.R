# Trava de segurança contra ciclagem
MAX_ITER <- 10000

# Roda o simplex a partir de um Tableau que já tem a base válida
# Devolve list(status = "otimo"ou "ilimitado", tab = tableau final, ...)
simplex <- function(tab, nomes, politica = "largest", verbose = TRUE) {
  it <- 0
  repeat{
    j <- escolher_entrada(tab, politica)
    if (is.null(j)) {
      return(list(status = "otimo", tab = tab, iteracoes = it))
    }
    
    l <- escolher_saida(tab, j)
    if (is.null(l)) {
      return(list(status = "ilimitado", tab = tab, iteracoes = it, j = j))
    }
    
    it <- it + 1
    tab <- pivotear(tab, l, j)
    if (verbose) imprimir_tableau(tab, nomes, paste0("Iteração: ", it))
  }
}

# Dado um tableau ótimo, procura uma segunda solução ótima distinta.
# Devolve NULL se a solução ótima é única, senão list(x, tab, j, l)
# proj converte um vetor da FPI para as variáveis originais
# para comparar no espaço da PL original), o padrão compara direto na FPI
segunda_solucao <- function(tab, nomes, proj = identity, verbose = TRUE) {
  cr <- custos_reduzidos(tab)
  cand <- setdiff(which(abs(cr) < EPS), tab$base) # Não básicas com custo reduzido 0
  x1 <- proj(solucao_basica(tab))
  
  for (j in cand) {
    l <- escolher_saida(tab, j)
    
    if (is.null(l)) {
      # Direção ilimitada sem mudar o objetivo: caminha 1 unidade nela
      col <- tab$mat[2:(tab$m + 1), tab$m + j]
      x <- solucao_basica(tab)
      x[j] <- 1
      x[tab$base] <- x[tab$base] - col
      if (verbose) cat(sprintf("\nIteração extra: %s pode crescer sem limite sem alterar o objetivo\n",
                               nomes[j]))
      return(list(x = x, tab = NULL, j = j, l = NULL))
    }
    
    tab2 <- pivotear(tab, l, j)
    x2 <- solucao_basica(tab2)
    
    if(max(abs(proj(x2) - x1)) > EPS) {
      if (verbose) {
        imprimir_pivo(tab, nomes, l, j)
        imprimir_tableau(tab2, nomes, "Iteração extra (outra solução ótima)")
      }
      return(list(x = x2, tab = tab2, j = j, l = l))
    }
  }
  NULL
}