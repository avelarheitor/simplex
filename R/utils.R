# EPS é a tolerância global, troca por zero qualquer valor menor que ela em módulo
# Para não acumular erro numérico

EPS <- 1e-9

zerar_pequenos <- function(x, eps = EPS){
  x[abs(x) < eps] <- 0
  x
}