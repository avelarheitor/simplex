# tableau.R cuida de montar a tabela a partir da FPI e ler dela os resultados

# montar_tableau recebe a matriz, o vetor b e o vetor de custos obj e base.
# a função aloca uma matriz de zeros com m + 1 linhas e m + n + 1 colunas
montar_tableau <- function(A, b, obj, base) {
  m <- nrow(A)
  n <- ncol(A)
  stopifnot(length(b) == m,
            length(obj) == n,
            length(base) == m,
            all(b >= 0))
  stopifnot(max(abs(A[, base, drop = FALSE] - diag(m))) < EPS)
  
  mat <- matrix(0, nrow = m + 1, ncol = m + n + 1)
  mat[1, (m + 1):(m + n)] <- -obj
  mat[2:(m + 1), 1:m] <- diag(m)
  mat[2:(m + 1), (m + 1):(m + n)] <- A
  mat[2:(m + 1), m + n + 1] <- b
  
  tab <- list(mat = mat, base = base, m = m, n = n)
  canonizar_objetivo(tab)
}

# Devolve o elemento da linha 1 (objetivo), última coluna (m + n + 1).
# Começa em zero e, a cada pivô, vai acumulando o valor da função objetivo da
# solução básica atual.
valor_objetivo <- function(tab) {
  tab$mat[1, tab$m + tab$n + 1]
}

# Devolve as m primeiras linhas de entrada da linha 0, ou seja, a parte do registro
# Acumula as operações feitas ao longo dos pivôs, que no ótimo, contenha o vetor dual
dual_tableau <- function(tab) {
  tab$mat[1, 1:tab$m]
}

# Cria um vetor de n zeros, um por variável da FPI.
# Percorre as linhas das restrições e, para cada linha i, descobre qual variável
# é básica ali (tab$base[i]) e coloca nela o valor do lado direito dessa linha
# (tab$mat[i + 1, tab$m + tab$n + 1])
solucao_basica <- function(tab) {
  x <- numeric(tab$n)
  for (i in seq_len(tab$m)) {
    x[tab$base[i]] <- tab$mat[i + 1, tab$m + tab$n + 1]
  }
  x
}