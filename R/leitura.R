# trimws elimina \r de arquivos do windows
# linhas[linhas, ""] ignora linhas em branco
# readLines devolve um vetor de textos, um por linha de código
ler_pl <- function(caminho) {
  linhas <- trimws(readLines(caminho, warn = FALSE))
  linhas <- linhas[linhas != ""]
  
  # strsplit quebra o texto onde houver um ou mais espaços, "\\s+": um ou mais espaços em branco
  # strplit também devolve uma lista, mesmo com uma só linha de entrada.  
  # [[1]]: pega o primeiro elemento do vetor e as.numeric converte o vetor de textos em números
  n <- as.integer(linhas[1]) # número de variáveis
  m <- as.integer(linhas[2]) # número de restrições
  tipos <- as.numeric(strsplit(linhas[3], "\\s+")[[1]]) # se variáveis são não negativas ou livres
  # A linha 4 pode começar com "max" ou "min" (formato dos exemplos do professor).
  # Se não começar, assume-se max, como no exemplo do PDF.
  tok <- strsplit(linhas[4], "\\s+")[[1]]
  if (tok[1] %in% c("max", "min")) {
    sentido <- tok[1]        # guarda se é max ou min
    tok <- tok[-1]       # tok[-1] remove o primeiro elemento (a palavra)
  } else {
    sentido <- "max"
  }
  obj <- as.numeric(tok)     # coeficientes na função objetivo
  if (sentido == "min") obj <- -obj   # min c.x equivale a max (-c).x
  
  # Verifica condições falsas, checa se tipos e obj (c) têm exatamente o mesmo valor n
  # Chega se o arquivo tem linhas suficientes para m restrições e se os tipos são só 1, -1 ou 0.
  stopifnot(length(tipos) == n, length(obj) == n,
            length(linhas) >= 4 + m,
            all(tipos %in% c(1, -1, 0)))
  
  # Prepara a estrutura das restrições
  A <- matrix(0, nrow = m, ncol = n)
  sinais <- character(m)
  b <- numeric(m)
  
  # seq_len gera 1, 2, ..., m
  # linhas[4 + i] pega as linhas da restrição i, pois as restrições começam na linha 5
  # a linha "1 -1 <= 2" é quebrada em "1", "-1", "<=", "2".
  # cada linha de restrição tem sempre n coeficiêntes, depois do sinal, depois o lado direito
  # logo o total esperado é n + 2
  # campos[1:n] são os coeficiêntes. Eles vão para a linha i da matriz.
  # A[i, ] significa, linha i, todas as colunas
  # campos[n + 1] é o sinal, guardado como texto em sinais[i]
  # campos[n + 2] é o lado direito, convertido para b[i]
  for (i in seq_len(m)) {
    campos <- strsplit(linhas[4 + i], "\\s+")[[1]]
    stopifnot(length(campos) == n + 2)
    A[i, ] <- as.numeric(campos[1:n])
    sinais[i] <- campos[n + 1]
    b[i] <- as.numeric(campos[n + 2])
  }
  
  # Valida os sinais
  stopifnot(all(sinais %in% c("<=", ">=", "==")))
  
  # lista que será retornada para função definida ler_pl
  list(n = n, m = m, tipos = tipos, obj = obj, A = A, sinais = sinais, b = b, sentido = sentido)
}