# Descobre onde o projeto está
args_full <- commandArgs(trailingOnly = FALSE)
arq <- sub("^--file=", "", args_full[grep("^--file=", args_full)])
dir_base <- if (length(arq) > 0) dirname(normalizePath(arq)) else getwd()

# Carrega os módulos
for (f in c("utils", "leitura", "fpi", "posto_completo", "tableau",
            "pivoteamento", "politicas", "saida", "simplex", "auxiliar", "cli")) {
  source(file.path(dir_base, "R", paste0(f, ".R")))
}

# Lê os argumentos
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  cfg <- parse_args(args)
  configurar_saida(cfg$decimals, cfg$digits)
  
  # Lê o arquivo 
  pl <- ler_pl(cfg$filename)
  fpi <- para_fpi(pl)
  imprimir_fpi(fpi)
  
  # Remove restrições redundantes.
  # Se alguma contradiz as outras, o problema é inviável e a função termina ali.
  r <- remover_dependentes(fpi)
  if (r$inviavel) { imprimir_inviavel(); return(invisible(NULL)) }
  fpi <- r$fpi
  
  # Usa a base óbvia ou roda a fase 1. 
  # Se a auxiliar mostra que não há solução viável, imprime "inviavel" e sai.
  ini <- encontrar_base_viavel(fpi, fpi$nomes, cfg$policy)
  if (ini$status == "inviavel") { imprimir_inviavel(); return(invisible(NULL)) }
  
  # Roda o simplex de verdade, se ele detecta que a variável que entra não tem limite
  # imprime "ilimitado" e sai
  cat("\n=== Fase 2: Simplex ===\n")
  res <- simplex(ini$tab, fpi$nomes, cfg$policy)
  if (res$status == "ilimitado") { imprimir_ilimitado(); return(invisible(NULL)) }
  
  # proj é uma função que converte um vetor da FPI para as variáveis originais.
  # Ela é criada uma vez e reutilizada, e também é passada para segunda_solucao
  tab <- res$tab
  proj <- function(x) recuperar_primal(fpi, x)
  
  # solução_basica lê do tableau o valor de cada variável da FPI e proj desfaz a transformação
  # dual_tableau lê o dual da FPI no registro e dual_original o ajusta para a PL original
  # z é valor objetivo
  x <- proj(solucao_basica(tab))
  y <- dual_original(fpi, dual_tableau(tab))
  z <- valor_objetivo(tab)
  
  # Se a PL original era de minimização, o programa resolveu max(-c.x).
  # Desfaz o sinal para imprimir o objetivo e o dual da PL original.
  if (pl$sentido == "min") {
    z <- -z
    y <- -y
  }
  
  # Procura uma segunda solução básica.
  # Se não existe, x2 fica NULL, e o resultado é único.
  # Se existe, converte a segunda solução para as variáveis originais também.
  seg <- segunda_solucao(tab, fpi$nomes, proj)
  x2 <- if (is.null(seg)) NULL else proj(seg$x)
  
  # imprimir_otimo escolhe o formato pelo x2, NULL imprime "otimo" com uma solução
  # e não NULL imprime "otimo (multiplos)" com duas
  imprimir_otimo(z, x, y, x2)
  invisible(NULL)
}

# interactive() é TRUE quando está no console do RStudio e FALSE quando o script
# é executado pelo Rscript.
if (!interactive()) main()