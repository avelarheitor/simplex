# Custos reduzidos: parte das variáveis da linha 0 (vetor com n valores)
custos_reduzidos <- function(tab) {
  tab$mat[1, (tab$m + 1):(tab$m + tab$n)]
}

# Escolhe a variável que entra na base
# Devolve o índice j da variável, ou NULL se não há candidata (tableau ótimo)
escolher_entrada <- function(tab, politica = "largest") {
  cr <- custos_reduzidos(tab)
  cand <- which(cr < -EPS) # Candidatas: custo reduzido negativo
  
  if (length(cand) == 0) return(NULL)
  
  if (politica == "bland") return(cand[1]) # Menor índice
  
  # largest: o mais negativo (maior em módulo)
  # smallest: o menos negativo (menor em módulo)
  alvo <- switch(politica,
                largest = min(cr[cand]),
                smallest = max(cr[cand]),
                stop("Política Inválida: ", politica))
  
  empatadas <- cand[abs(cr[cand] - alvo) < EPS]
  # Empate: Bland (menor índice)
  empatadas[1]
}

# Escolhe a restrição referente a variável básica que sai da base
# Recebe a variável j que entra e devolve o índice l da que sai
# ou NULL se nenhuma razão é possível (problema ilimitado)
escolher_saida <- function(tab, j) {
  m <- tab$m
  col <- tab$mat[2:(m + 1), m + j] # Coluna de j nas restrições
  rhs <- tab$mat[2:(m + 1), m + tab$n + 1] # Lado direito
  
  # Só entradas positivas
  elegiveis <- which(col > EPS) 
  if (length(elegiveis) == 0) return(NULL)
  
  razoes <- rhs[elegiveis] / col[elegiveis]
  minimo <- min(razoes)
  empatadas <- elegiveis[abs(razoes - minimo) < EPS]
  
  # Empate: Bland, sai a variável básica de menor índice
  empatadas[which.min(tab$base[empatadas])]
}