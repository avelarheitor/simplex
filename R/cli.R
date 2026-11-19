# Arquivo que organiza e possibilita o comando de rodar o simplex no arquivo específico
# Garante quais argumetos e como devem ser passados.
parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  cfg <- list(filename = NA_character_, decimals = 3L, digits = 7L,
              policy = "largest")
  
  i <- 1
  while(i <= length(args)) { 
    a <- args[i]
    if (a %in% c("--decimals", "--digits", "--policy")) {
      if (i == length(args)) stop("faltou o valor depois de ", a)
      val <- args[i + 1]
      if (a == "--decimals") cfg$decimals <- as.integer(val)
      if (a == "--digits") cfg$digits <- as.integer(val)
      if (a == "--policy") cfg$policy <- val
      i <- i + 2
    } else if (startsWith(a, "--")) {
      stop("Opção desconhecida: ", a)
    } else {
      cfg$filename <- a
      i <- i + 1
    }
  }
  
  if (is.na(cfg$filename)) stop("uso: Rscript meusimplex.R arquivo.txt [--decimals N] [--digits N] [--policy P]")
  if (!file.exists(cfg$filename)) stop("arquivo não encontrado: ", cfg$filename)
  if (is.na(cfg$decimals) || cfg$decimals < 0) stop("--decimals inválido")
  if (is.na(cfg$digits) || cfg$digits < 1) stop("--digits inválido")
  if (!cfg$policy %in% c("largest", "bland", "smallest"))
    stop("--policy deve ser largest, bland ou smallest")
  
  cfg
}