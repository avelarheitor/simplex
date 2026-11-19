# Operação central do simplex

# A função copia a matriz do tableau para mat e percorre as restrições, uma por uma
# f, que é o valor da linha 0 nessa coluna. Se f não for zero, não a nada a se fazer
# Se diferente de 0, a função subtrai da linha 0 o valor f vezes a linha da restrição i.
# Essa subtração zera exatamente a entrada f da linha 0.

# A subtração é feita na linha inteira (mat[1, ]), incluindo o registro de operações
# e o lado direito, e não só as colunas das variáveis
canonizar_objetivo <- function(tab) {
  mat <- tab$mat
  for (i in seq_len(tab$m)) {
    col <- tab$m + tab$base[i]
    f <- mat[1, col]
    if (f != 0) mat[1, ] <- mat[1, ] - f * mat[i + 1, ]
  }
  tab$mat <- zerar_pequenos(mat)
  tab
}

# A função recebe o tableau, l e j.
# l é o número da restrição que a variável básica vai sair
# j é o número da variável que vai entrar, ambos na numeração da FPI
pivotear <- function(tab, l, j) {
  mat <- tab$mat
  col <- tab$m + j
  lin <- l + 1
  p <- mat[lin, col]
  stopifnot(abs(p) > EPS)
  
  # Duas etapas da operação:
  # Dividir a linha do pivô por p. Isso deixa 1 na posição do pivô, e o resto da
  # linha é reescalonado junto, inclusive o registro e o lado direito
  # Zera o resto da coluna, o laço percorre todas as linhas, menos a do pivô
  # Para cada uma, pega o valor atual dela na coluna do pivô (f) e se diferente de zero
  # Subtrai f vezes a linha do pivô
  
  # No fim, a coluna col virou uma coluna de identidade.
  mat[lin, ] <- mat[lin, ] / p
  for (r in seq_len(nrow(mat))) {
    if (r != lin) {
      f <- mat[r, col]
      if (f != 0) mat[r, ] <- mat[r, ] - f * mat[lin, ]
    }
  }
  
  tab$mat <- zerar_pequenos(mat)
  tab$base[l] <- j
  tab
}