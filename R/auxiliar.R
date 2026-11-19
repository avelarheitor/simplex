# O simplex só começa a andar quando se tem uma base viável, o arquivo procura essa base,
# se a base existir nas colunas de A é usada, se não, é montado a PL auxiliar,
# resolve e com isso, ou tira uma base viável, ou se descobre que o problema é inviável


base_obvia <- function(A) {
  m <- nrow(A)
  base <- integer(m)
  for (j in seq_len(ncol(A))) {
    col <- A[, j]
    nz <- which(abs(col) > EPS)
    if (length(nz) == 1 && abs(col[nz] - 1) < EPS && base[nz] == 0) {
      base[nz] <- j
    }
  }
  base
}

encontrar_base_viavel <- function(fpi, nomes, politica = "largest", verbose = TRUE) {
  m <- fpi$m
  n <- fpi$n_fpi
  
  base <- base_obvia(fpi$A)
  sem <- which(base == 0)
  k <- length(sem)
  
  # Base óbvia é encontrada
  if (k == 0) {
    if (verbose) cat("\nBase inicial óbvia encontrada; PL auxiliar dispensada.\n")
    tab <- montar_tableau(fpi$A, fpi$b, fpi$obj, base)
    if (verbose) imprimir_tableau(tab, nomes, "Tableau inicial da fase 2")
    return(list(status = "viavel", tab = tab))
  }
  
  # Monta a PL Auxiliar
  if (verbose) cat("\n=== Fase 1: PL Auxiliar ===\n")
  Aaux <- cbind(fpi$A, matrix(0, m, k))
  for (t in seq_len(k)) {
    Aaux[sem[t], n + t] <- 1
    base[sem[t]] <- n + t
  }
  
  obj_aux <- c(rep(0, n), rep(-1, k))
  nomes_aux <- c(nomes, paste0("a", sem - 1))
  
  # Monta tableau da auxiliar
  tab <- montar_tableau(Aaux, fpi$b, obj_aux, base)
  if (verbose) imprimir_tableau(tab, nomes_aux, "Tableau Inicial da PL Auxiliar")
  
  # Roda o mesmo simplex da fase 2, agora na auxiliar.
  res <- simplex(tab, nomes_aux, politica, verbose)
  tab <- res$tab
  
  # Se o ótimo da auxiliar é negativo, não dá para zerar as artificiais, ou seja,
  # não há solução que satisfaça
  if (valor_objetivo(tab) < -EPS) {
    return(list(status = "inviavel", tab = tab))
  }
  
  # Retira artificiais que ficaram na base com valor 0
  for (i in seq_len(m)) {
    if (tab$base[i] > n) {
      linha <- tab$mat[i + 1, (m + 1):(m + n)]
      if (max(abs(linha)) < EPS) {
        stop("Artificial presa na base em linha nula (linha redundante não removida)")
      }
      j <- which.max(abs(linha))
      if (verbose) imprimir_pivo(tab, nomes_aux, i, j)
      tab <- pivotear(tab, i, j)
    }
  }
  
  # Descarta as colunas artificiais e retoma a função objetivo original
  mat <- tab$mat[, -(m + n + seq_len(k)), drop = FALSE]
  mat[1, ] <- 0
  mat[1, (m + 1):(m + n)] <- -fpi$obj
  tab2 <- canonizar_objetivo(list(mat = mat, base = tab$base, m = m, n = n))
  
  if (verbose) {
    cat("\n=== Fase 1 Concluída: base viável encontrada ===\n")
    imprimir_tableau(tab2, nomes, "Tableau Inicial da Fase 2")
  }
  list(status = "viavel", tab = tab2)
}