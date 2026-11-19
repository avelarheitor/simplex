# Simplex em R

Trabalho prático de **DCC035 - Pesquisa Operacional (2026.1)**: implementação do método Simplex (duas fases) para resolver Programas Lineares gerais, com impressão do passo a passo no console.

O programa lê uma PL de um arquivo texto, converte para a Forma Padrão de Igualdade (FPI), encontra uma base viável (PL auxiliar, quando necessário), roda o Simplex e informa se o problema é **inviável**, **ilimitado**, **ótimo** ou **ótimo com múltiplas soluções**. As operações de pivoteamento foram implementadas manualmente.

## Requisitos

- R instalado e o comando `Rscript` disponível no terminal.
- Nenhum pacote externo: todo o código usa apenas o R base.

## Estrutura do diretório

```
simplex-po/
├── meusimplex.R          # ponto de entrada do programa
├── R/                    # módulos com as funções
│   ├── utils.R
│   ├── leitura.R
│   ├── fpi.R
│   ├── posto_completo.R
│   ├── tableau.R
│   ├── pivoteamento.R
│   ├── politicas.R
│   ├── simplex.R
│   ├── auxiliar.R
│   ├── saida.R
│   └── cli.R
├── instancias/           # PLs de teste 
├── saidas/               # saídas salvas (opcional)
├── README.md
├── .gitignore
└── simplex-po.Rproj      # projeto do RStudio
```

## Visão geral do fluxo

O `meusimplex.R` executa as etapas na ordem pedida no enunciado:

```
arquivo .txt
   │
   ▼
 leitura.R ............ lê a PL e devolve a lista `pl`
   │
   ▼
 fpi.R ................ converte para FPI (max c.x, Ax = b, x >= 0, b >= 0)
   │
   ▼
 posto_completo.R ..... remove restrições redundantes (ou detecta inviabilidade)
   │
   ▼
 auxiliar.R ........... usa base óbvia, ou roda a PL auxiliar (fase 1)
   │                    ├─ inviável  -> "Status: inviavel"
   ▼                    └─ viável    -> tableau pronto para a fase 2
 simplex.R ............ fase 2: itera até o ótimo
   │                    ├─ ilimitado -> "Status: ilimitado"
   ▼                    └─ ótimo
 simplex.R ............ procura uma 2ª solução ótima (múltiplas soluções)
   │
   ▼
 saida.R .............. imprime "Status / Objetivo / Solucao / Dual"
```

Durante todo o processo, o `saida.R` imprime o tableau e o pivô de cada iteração.

## O que cada arquivo faz

### Raiz

| Arquivo | Função |
|---|---|
| `meusimplex.R` | Ponto de entrada. Descobre a pasta do projeto, carrega (`source`) todos os arquivos de `R/` e define a função `main()`, que executa o fluxo completo. Ao rodar via `Rscript`, chama `main()` automaticamente; no console do R apenas carrega as funções. |
| `README.md` | Este arquivo. |
| `.gitignore` | Arquivos que o git deve ignorar (por exemplo `.Rhistory`, `.RData`, `.Rproj.user/`). |
| `simplex-po.Rproj` | Arquivo de projeto do RStudio. |

### Pasta `R/`

| Arquivo | Principais funções | O que faz |
|---|---|---|
| `utils.R` | `EPS`, `zerar_pequenos()` | Define a tolerância numérica global (`EPS = 1e-9`) e troca por zero valores menores que ela, para evitar acúmulo de erro de ponto flutuante. |
| `leitura.R` | `ler_pl()` | Lê o arquivo de entrada e devolve uma lista com `n`, `m`, `tipos`, `obj`, `A`, `sinais`, `b` e `sentido`. Aceita a linha do objetivo com ou sem `max`/`min` na frente. Se for `min`, multiplica os custos por -1 para tratar como `max`. |
| `fpi.R` | `para_fpi()`, `recuperar_primal()`, `dual_original()` | Converte para a FPI: variáveis não positivas viram `x = -x'`, livres viram `x = x+ - x-`, desigualdades ganham folga (`<=`) ou excesso (`>=`), e linhas com `b < 0` são multiplicadas por -1. Guarda de onde veio cada coluna (para voltar às variáveis originais) e quais linhas foram invertidas (para corrigir o sinal do dual). |
| `posto_completo.R` | `remover_dependentes()` | Elimina restrições linearmente dependentes (eliminação de Gauss linha a linha). Se uma linha for dependente mas com lado direito incompatível, sinaliza que a PL é inviável. |
| `tableau.R` | `montar_tableau()`, `valor_objetivo()`, `dual_tableau()`, `solucao_basica()` | Monta o tableau estendido e lê resultados dele: valor da função objetivo, vetor dual e solução básica atual. |
| `pivoteamento.R` | `canonizar_objetivo()`, `pivotear()` | `pivotear()` é a operação de pivô, feita à mão. `canonizar_objetivo()` zera a linha do objetivo nas colunas básicas (necessário quando a base inicial tem custo, como na PL auxiliar). |
| `politicas.R` | `custos_reduzidos()`, `escolher_entrada()`, `escolher_saida()` | Decide qual variável entra (regras `largest`, `smallest`, `bland`) e qual sai (teste da razão mínima, com desempate de Bland). Devolve `NULL` quando o tableau é ótimo (nenhuma entrada) ou o problema é ilimitado (nenhuma saída). |
| `simplex.R` | `simplex()`, `segunda_solucao()` | `simplex()` é o laço principal (entra, sai, pivoteia, imprime) e devolve `"otimo"` ou `"ilimitado"`. `segunda_solucao()` testa variáveis não básicas com custo reduzido zero para achar outra solução ótima distinta. |
| `auxiliar.R` | `base_obvia()`, `encontrar_base_viavel()` | `base_obvia()` procura colunas da identidade em `A`. `encontrar_base_viavel()` usa essa base se ela for completa; senão monta a PL auxiliar com variáveis artificiais, resolve, decide a viabilidade, expulsa artificiais que sobrarem na base e devolve o tableau da fase 2. |
| `saida.R` | `configurar_saida()`, `fmt_num()`, `imprimir_tableau()`, `imprimir_pivo()`, `imprimir_fpi()`, `imprimir_otimo()`, `imprimir_inviavel()`, `imprimir_ilimitado()` | Toda a impressão do programa. Guarda `--decimals` e `--digits` e formata os números com largura e casas fixas. |
| `cli.R` | `parse_args()` | Lê e valida os argumentos de linha de comando (`filename`, `--decimals`, `--digits`, `--policy`) e devolve a configuração. |

### Pasta `instancias/`

Contém as PLs de teste fornecidas: arquivos sem extensão, nomeados `01` a `25` (mais `04b` e `teste_min.txt`).

### Pastas `saidas/` e `docs/`

- `saidas/`: local para guardar a saída do programa (por exemplo `> saidas/01.txt`).
- `docs/`: documentação e relatório do trabalho.

## Como os módulos conversam

Os dados passam entre os módulos em três estruturas (todas listas do R):

| Estrutura | Criada por | Conteúdo | Usada por |
|---|---|---|---|
| `pl` | `ler_pl()` | A PL como foi escrita no arquivo: `n`, `m`, `tipos`, `obj`, `A`, `sinais`, `b`, `sentido`. | `para_fpi()` |
| `fpi` | `para_fpi()` | A PL na FPI (`A`, `b`, `obj`) mais metadados para voltar ao problema original: `origem`, `sinal`, `nomes`, `invertida`, `n_orig`, `n_fpi`, `m`, `m_orig`, `linhas_mantidas`. | `remover_dependentes()`, `encontrar_base_viavel()`, `recuperar_primal()`, `dual_original()`, `imprimir_fpi()` |
| `tab` | `montar_tableau()` | O tableau (`mat`), o vetor `base` (variável básica de cada restrição) e os tamanhos `m` e `n`. | `pivotear()`, `escolher_entrada()`, `escolher_saida()`, `simplex()`, `segunda_solucao()`, `imprimir_tableau()` |

Quem chama quem, em resumo:

- `meusimplex.R` chama `parse_args`, `configurar_saida`, `ler_pl`, `para_fpi`, `remover_dependentes`, `encontrar_base_viavel`, `simplex`, `segunda_solucao` e as funções de impressão.
- `encontrar_base_viavel` reaproveita `simplex` (para resolver a PL auxiliar), `montar_tableau`, `pivotear` e `canonizar_objetivo`.
- `simplex` usa `escolher_entrada`, `escolher_saida`, `pivotear` e `imprimir_tableau`.
- `segunda_solucao` usa `custos_reduzidos`, `escolher_saida`, `pivotear` e `solucao_basica`.
- Todos os módulos de cálculo usam `EPS` e `zerar_pequenos` do `utils.R`; todas as impressões passam por `fmt_num` do `saida.R`.

### O tableau estendido

O tableau tem `m + 1` linhas e `m + n + 1` colunas:

```
linha 0:        |  0 (registro)  |  -c  (variáveis)  |  valor do objetivo |
linhas 1..m:    |  I (registro)  |  A   (variáveis)  |  b                 |
```

As primeiras `m` colunas (o "registro", impressas como `y0, y1, ...`) acumulam todas as operações de linha feitas. Por isso, no tableau ótimo, a parte do registro na linha 0 contém o **vetor dual**, e o canto inferior direito contém o **valor da função objetivo**.

## Como usar

Todos os comandos abaixo são executados no **terminal** (no RStudio, a aba *Terminal*), dentro da pasta do projeto.

### Sintaxe

```
Rscript meusimplex.R <arquivo> [--decimals N] [--digits N] [--policy P]
```

| Argumento | Descrição | Padrão |
|---|---|---|
| `arquivo` | Caminho do arquivo com a PL. | (obrigatório) |
| `--decimals N` | Número de casas decimais nos valores impressos. | `3` |
| `--digits N` | Número total de dígitos (largura) dos valores impressos. | `7` |
| `--policy P` | Regra de escolha da variável que entra: `largest`, `bland` ou `smallest`. | `largest` |

As opções podem vir antes ou depois do nome do arquivo, em qualquer ordem. Os números são impressos como em `sprintf("%7.3f", x)` (largura total de 7 e 3 casas, no exemplo).

### Exemplos

Rodar um exemplo com a regra de Bland:

```
Rscript meusimplex.R instancias/01 --decimals 3 --digits 7 --policy bland
```

Rodar com os valores padrão:

```
Rscript meusimplex.R instancias/01
```

Mostrar só o resultado final (Linux, macOS ou Git Bash):

```
Rscript meusimplex.R instancias/01 | tail -n 6
```

Salvar a saída completa em um arquivo:

```
Rscript meusimplex.R instancias/01 > saidas/01.txt
```

Rodar todos os exemplos, mostrando só o final de cada um (Linux, macOS ou Git Bash):

```
for f in instancias/*; do echo "== $f"; Rscript meusimplex.R $f --policy bland | tail -n 6; done
```

### Usando pelo console do R

```r
setwd("caminho/para/simplex-po")   # pasta do projeto
source("meusimplex.R")             # só carrega as funções
main(c("instancias/01", "--decimals", "3", "--digits", "7", "--policy", "bland"))
```

Ao usar `source`, o programa não executa sozinho: é preciso chamar `main(...)` com os argumentos num vetor.

### Problemas comuns

- **`Rscript` não é reconhecido (Windows):** o R não está no PATH. Use o caminho completo do executável, por exemplo `"C:\Program Files\R\R-x.y.z\bin\Rscript.exe" meusimplex.R ...`.
- **`unexpected symbol` ao digitar o comando:** o comando foi digitado no console do R. `Rscript ...` deve ser digitado no terminal.
- **Mudou um arquivo de `R/` e nada mudou:** salve o arquivo. Se estiver usando o console, rode `rm(list = ls())` e o `source` novamente. Com `Rscript` isso não é necessário, pois cada execução carrega tudo do zero.

## Formato do arquivo de entrada

```
n                                  número de variáveis
m                                  número de restrições (sem as de sinal das variáveis)
t1 t2 ... tn                       tipo de cada variável: 1 (>= 0), -1 (<= 0), 0 (livre)
[max|min] c1 c2 ... cn             coeficientes da função objetivo
a11 ... a1n  <sinal>  b1           restrição 1 (sinal: <=, >= ou ==)
...
am1 ... amn  <sinal>  bm           restrição m
```

A palavra `max` ou `min` na linha do objetivo é opcional; sem ela, o problema é tratado como `max`. Espaços extras, linhas em branco e quebras de linha do Windows são aceitos.

Exemplo (`instancias/01`):

```
3
3
1 1 1
max 2 4 8
1 0 0 <= 1
0 1 0 <= 1
0 0 1 <= 1
```

## Formato da saída

Além do passo a passo (FPI, tableaus e pivôs), o programa termina com um dos resultados abaixo. As variáveis são indexadas a partir de zero (`x0`, `x1`, ...).

**Inviável:**

```
Status: inviavel
```

**Ilimitado:**

```
Status: ilimitado
```

**Ótimo (solução única):**

```
Status: otimo
Objetivo:  14.000
Solucao:
  1.000   1.000   1.000
Dual:
  2.000   4.000   8.000
```

**Ótimo com múltiplas soluções** (executa uma iteração extra e imprime duas soluções ótimas distintas):

```
Status: otimo (multiplos)
Objetivo: z
Solucoes:
v1 v2 v3 ...
u1 u2 u3 ...
Dual:
w1 w2 w3 ...
```

## Resultados esperados nos exemplos

Valores de referência calculados com um solver independente (`linprog` do SciPy), para conferência de `Status` e `Objetivo`:

| Status | Exemplos (objetivo, quando ótimo) |
|---|---|
| Ótimo | `01` (14), `04` (50), `04b` (50), `08` (11), `09` (14), `10` (0), `11` (12), `12` (94.2), `18` (36), `19` (3.9928), `20` (11.0199), `25` (1.8) |
| Inviável | `02`, `05`, `06`, `07`, `23`, `24` |
| Ilimitado | `03`, `13`, `14`, `15`, `16`, `17`, `21`, `22` |

Em todo resultado ótimo, vale conferir a **dualidade forte**: o produto escalar do vetor dual pelo vetor `b` deve ser igual ao valor de `Objetivo`.

## Decisões de implementação

- **Tableau estendido com registro de operações**, o que permite ler o dual diretamente do tableau final.
- **Políticas de entrada:** `bland` escolhe o menor índice entre as candidatas (custo reduzido negativo); `largest` escolhe o custo reduzido mais negativo (maior em módulo); `smallest` escolhe o menos negativo (menor em módulo). Nas duas últimas, o empate é resolvido por Bland (menor índice).
- **Teste da razão:** só considera entradas positivas na coluna; o empate é resolvido por Bland (sai a variável básica de menor índice). Isso evita ciclagem nos empates, e há ainda um limite de segurança de iterações (`MAX_ITER`) em `simplex.R`.
- **Tolerância numérica:** valores com módulo menor que `EPS = 1e-9` são tratados como zero após cada pivô.
- **PL auxiliar só quando necessária:** se `A` já contém colunas da identidade em todas as linhas (por exemplo, folgas de restrições `<=` com `b >= 0`), a fase 1 é dispensada. Caso contrário, só as linhas sem base recebem variável artificial.
- **Linhas redundantes** são removidas antes da fase 1; o dual dessas linhas é impresso como zero.
- **Dual da PL original:** o dual lido do tableau é da FPI; `dual_original()` corrige o sinal das linhas que foram multiplicadas por -1 e recoloca zeros nas linhas removidas.
- **Múltiplas soluções:** `segunda_solucao()` testa as variáveis não básicas com custo reduzido zero e só aceita uma segunda solução se ela for diferente da primeira **nas variáveis originais** (um custo reduzido zero sozinho não garante múltiplas soluções, por causa da degeneração). Se a variável pode crescer sem limite sem alterar o objetivo, a segunda solução é obtida avançando uma unidade nessa direção.
- **Indexação:** internamente o R usa índices a partir de 1; na impressão, as variáveis aparecem a partir de 0, como pede o enunciado. As variáveis auxiliares da FPI recebem nomes próprios: `x1+` e `x1-` (parte positiva e negativa de uma variável livre), `x1'` (variável não positiva trocada de sinal), `f0, f1, ...` (folgas e excessos) e `a0, a1, ...` (artificiais da fase 1).