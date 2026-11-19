# Empacota uma coluna da FPI
# col: vetor com coeficientes da coluna na matriz A
# custo: coeficiente dessa coluna na função objetivo
# origem: índice da variável original de onde essa coluna veio
# sinal: +1 ou -1, diz como essa coluna entra na reconstrução da variável
# nome: texto usado na impressão

nova_coluna <- function(col, custo, origem, sinal, nome) {
  list(col = col, custo = custo, origem = origem, sinal = sinal, nome = nome)
}

# Recebe a pl de ler_pl e devolve a PL na FPI
para_fpi <- function(pl) {
  m <- pl$m # Número de restrições
  itens <- list()   # cada item é uma coluna da FPI, 
  # vai acrescentando as colunas aqui até a construção da matriz A
  
  # Variáveis originais
  # Percorre as n variáveis da PL e cria 1 ou duas colunas para cada uma, 
  # dependendo do tipo (1 = >=0, -1 = <=0, 0 = livre)
  for (j in seq_len(pl$n)) {
    aj <- pl$A[, j] # coluna j da matriz original (tamanho m)
    cj <- pl$obj[j] # custo da variável j na função objetivo
    nj <- paste0("x", j - 1) # saída usa índice começando em 0
    
    if (pl$tipos[j] == 1) {
      # caso x_j >= 0: já está na forma desejada, a coluna passa sem mudança
      itens[[length(itens) + 1]] <- nova_coluna(aj, cj, j, 1, nj)
      
    } else if (pl$tipos[j] == -1) {
      # caso x_j <=0: troca de variável x_j = -x', com x' = >=0.
      # Substitui x_j por -x' inverte o sinal da coluna e do custo.
      # sinal = -1 registra que, para voltar, x_j = -(valor de x').
      itens[[length(itens) + 1]] <- nova_coluna(-aj, -cj, j, -1, 
                                                paste0(nj, "'"))
      
    } else {
      # Caso x_j livre: x_j = x+ - x-, com x+ >= 0 e x- >= 0.
      # Vira duas colunas:
      #   x+  entra com a coluna original (sinal +1)
      #   x-  entra com a coluna invertida (sinal -1)
      # Para voltar: x_j = (valor de x+) - (valor de x-).
      itens[[length(itens) + 1]] <- nova_coluna(aj, cj, j, 1, 
                                                paste0(nj, "+"))
      itens[[length(itens) + 1]] <- nova_coluna(-aj, -cj, j, -1, 
                                                paste0(nj, "-"))
    }
  }
  
  # Folgas e excessos
  for (i in seq_len(m)) {
    if (pl$sinais[i] != "==") {
      col <- numeric(m)
      col[i] <- if (pl$sinais[i] == "<=") 1 else -1
      itens[[length(itens) + 1]] <- nova_coluna(col, 0, NA_integer_, 1, 
                                                paste0("f", i - 1))
    }
  }
  
  # Juntar tudo
  
  # Transforma a lista de colunas em estruturas que o resto do programa usa
  
  # do.call(cbind, lista) equivale a cbind(col1, col2, ...):
  # coloca as colunas lado a lado e forma a matriz A da FPI (m linhas x n_fpi colunas).
  A <- do.call(cbind, lapply(itens, function(it) it$col))
  # sapply extrai um campo de cada item e devolve um vetor com um valor por coluna
  custos <- sapply(itens, function(it) it$custo) # vetor c da FPI
  origem <- sapply(itens, function(it) it$origem) # variável original de cada coluna
  sinal <- sapply(itens, function(it) it$sinal) # +1 / -1 de cada coluna
  nomes <- sapply(itens, function(it) it$nome) # nomes para impressão
  
  # Garantir b >= 0
  # se b_i < 0, multiplica a linha i inteira por -1
  b <- pl$b
  invertida <- b < 0
  A[invertida, ] <- -A[invertida, , drop = FALSE]
  b[invertida] <- -b[invertida]
  
  # Devolve a FPI com os dados
  list(A = A, b = b, obj = custos,
       origem = origem, sinal = sinal, nomes = nomes,
       invertida = invertida,
       n_orig = pl$n, n_fpi = ncol(A), m = m,
       m_orig = m, linhas_mantidas = seq_len(m))
}

# Converte uma solução da FPI (vetor de x_fpi com n_fpi) de volta para as 
# variáveis da PL original (vetor com n_orig valores)

# Para cada coluna k da FPI:
# se veio de uma variável original j, soma sinal[k] * x_fpi[k] em x[j]
# se é folga/excesso (origem NA), é ignorada
# Somar (em vez de atribuir) é o que faz a variável livre funcionar:
# x_j = (+1)*x+ + (-1)*x-.
recuperar_primal <- function(fpi, x_fpi) {
  x <- numeric(fpi$n_orig)
  for (k in seq_len(fpi$n_fpi)) {
    j <- fpi$origem[k]
    if (!is.na(j)) x[j] <- x[j] + fpi$sinal[k] * x_fpi[k]
  }
  x
}

# Converte o dual da FPI para o dual da PL Original:
# linhas multiplicadas por -1 na FPI têm a variável dual com sinal trocado.
dual_original <- function(fpi, y) {
  y_full <- numeric(fpi$m_orig)
  y_full[fpi$linhas_mantidas] <- y       # linhas removidas ficam com dual 0
  y_full[fpi$invertida] <- -y_full[fpi$invertida]
  y_full
}