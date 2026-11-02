# The Cloud-Native Observability Maturity Model (CN-OMM): A Design Science Formalization, Automated Assessment Protocol, and Empirical Chaos Validation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Method: Design Science Research](https://img.shields.io/badge/Methodology-Design%20Science%20Research%20(DSR)-blue.svg)]()
[![Evaluation: Helgesson Type 1 & 3](https://img.shields.io/badge/Validation-Type--1%20%26%20Type--3%20Chaos%20Evaluation-success.svg)]()
[![Template: ACM sigconf](https://img.shields.io/badge/Template-ACM%20acmart%20(sigconf)-purple.svg)]()

Este repositório contém o **Pacote de Replicação (Replication Package)** completo, auditável e aberto do artigo científico ***"The Cloud-Native Observability Maturity Model (CN-OMM): A Design Science Formalization, Automated Assessment Protocol, and Empirical Chaos Validation"***, formatado no template oficial da **Association for Computing Machinery (ACM `acmart` / `sigconf`)** e estruturado em conformidade com as diretrizes de Ciência Aberta (*ACM/IEEE Open Science & Empirical Standards*).

O pacote consolida:
1. A fundamentação teórica e matemática do **Cloud-Native Observability Maturity Model (CN-OMM)** sob a metodologia **Design Science Research (DSR)** (Hevner et al., 2004; Becker et al., 2009 [Requisitos R1–R8]; De Bruin et al., 2005; Lasrado et al., 2015);
2. A matriz arquitetural **$5\text{ Níveis} \times 5\text{ Dimensões Ortogonais}$** composta por **15 subcomponentes** e **15 Indicadores Quantitativos de Capacidade ($\text{QCI}_{1.1}$ a $\text{QCI}_{5.3}$)**;
3. O motor automatizado de avaliação de maturidade (`scripts/evaluate_cn_omm.py`), que calcula a maturidade efetiva não-compensatória (*Stage-Gate*) e o Índice de Progressão Euclidiano $\mathcal{I}(\mathcal{S})$ diretamente sobre metadados e telemetria do cluster;
4. Os datasets brutos (`data/`) e scripts de validação empírica **Type-3** (Helgesson et al., 2012) em Kubernetes sob injeção controlada de falhas via Chaos Engineering ($N = 30$ *paired trials* no benchmark *CNCF OpenTelemetry Astronomy Shop*).

---

## Sumário Executivo do Modelo (CN-OMM)

| Nível de Maturidade | Escopo Arquitetural | Equação / Estado de Telemetria | Comportamento Empírico Observado ($N=30$ Chaos Trials) |
| :--- | :--- | :--- | :--- |
| **Level 1: Opaque** *(Blind Execution)* | Logs efêmeros em `stdout` local sem persistência ou contexto. | $\mathcal{O}(t) \approx \emptyset, \; \text{rank}(\mathcal{O}) = 0$ | Detecção exclusivamente pós-morte via reclamação de usuários externos. |
| **Level 2: Reactive** *(Disjoint Polling)* | Coleta de infraestrutura (`kubelet`/cAdvisor) e triagem manual via CLI (`kubectl top/logs`). | $\text{Level}_{\text{eff}} = 2, \; \mathcal{I}(\mathcal{S}) = 0.266$ | **$MTTDiag$ Mediano:** $300.00\,\text{s}$ \| **Acurácia ($Acc$):** $20.00\%$ ($6/30$). Cego a degradações de rede e CPU throttling. |
| **Level 3: Fragmented** *(Siloed Pillars)* | Coleta centralizada de $M, L, T$ em silos isolados sem decomposição de tempo próprio ($T_{\text{self}}$). | $\bar{C} = 2.93$, mas **Gargalo Stage-Gate em $D_2 = 2.33 \Rightarrow \text{Level}_{\text{eff}} = 2^*$** | **Falácia da Aditividade Monomodal:** Detecção rápida ($18.66\,\text{s}$), mas **Acurácia ($Acc$) = $0.00\%$ ($0/30$)** devido ao *Cascading Span Bias*. |
| **Level 4: Correlated** *(Multimodal Fusion — PANOPTES)* | OTel + eBPF zero-code, W3C TraceContext em logs, Exemplars, $T_{\text{self}}$, Chaos Probes e armazenamento *index-free*. | $\text{Level}_{\text{eff}} = 4, \; \mathcal{I}(\mathcal{S}) = 0.833$ | **$MTTDiag$ Mediano:** **$17.27\,\text{s}$** ($-94.24\%, p = 3.06 \times 10^{-5}$) \| **Acurácia ($Acc$):** **$83.33\%$** ($25/30, p = 7.74 \times 10^{-7}$) \| **$\Delta_{\text{CPU}}$:** **$9.51\% \pm 2.14\%$** ($< 15\%$). |
| **Level 5: Autonomous** *(Adaptive AIOps)* | Ponderação adaptativa FinOps/GreenOps ($w_i = \alpha_i S_i$), inferência causal GNN/LLM e *self-healing* autônomo. | $\text{Level}_{\text{eff}} = 5, \; \mathcal{I}(\mathcal{S}) = 1.000$ | Remediação em malha fechada governada por *Error Budgets* e verificação contínua de caos. |

---

## Estrutura do Repositório

```text
├── data/
│   ├── cn_omm_cluster_assessments.csv             # Matriz auditada dos 15 subcomponentes (d1.1..d5.3), C(Dk), Stage-Gate e Índice Euclidiano
│   ├── scenario1_workload_baseline.csv            # Série temporal de baseline sem instrumentação (N=30 janelas)
│   ├── scenario2_overhead_panoptes.csv            # Série temporal do Probe Effect (CPU/RAM) no Nível 4 (PANOPTES)
│   ├── scenario3_diagnostic_trials.csv            # Campanhas pareadas N=30 — Baseline A: Nível 2 (Native CLI)
│   ├── scenario3_diagnostic_trials_stratified.csv # Campanhas pareadas estratificadas por modalidade de falha (Nível 2)
│   ├── scenario4_diagnostic_trials.csv            # Campanhas pareadas N=30 — Baseline B: Tentativa Nível 3 (Siloed Tracing)
│   └── scenario4b_optimized_trials.csv            # Campanhas pareadas N=30 — Tratamento: Nível 4 (PANOPTES Multimodal + T_self)
├── figures/
│   ├── fig-cn-omm-architecture.tex                # Diagrama arquitetural e metodológico DSR em TikZ nativo
│   ├── fig_omm_radar_profiles.png                 # Gráfico radar pentadimensional dos perfis avaliados (destacando o gargalo D2)
│   └── fig_omm_pareto_frontier.png                # Trajetória empírica de Acurácia, MTTDiag e Probe Effect (CPU %)
├── scripts/
│   └── evaluate_cn_omm.py                         # Motor de avaliação automatizada CN-OMM, testes estatísticos e geração das figuras
├── sections/
│   ├── 01.introduction.tex                        # Contextualização, lacunas (Vendor Bias, Probe Effect, Cascading Bias) e RQs
│   ├── 02.background_foundations.tex              # Observabilidade de Kalman, DSR (Becker/De Bruin) e Teoria Configuracional
│   ├── 03.critical_analysis_existing_models.tex   # Auditoria comparativa de 7 modelos existentes (Requisito R1 de Becker)
│   ├── 04.cn_omm_formalization.tex                # Formalização matemática, 5 Dimensões (D1-D5), 15 Subcomponentes e Matriz 5x5
│   ├── 05.automated_assessment_protocol.tex       # Protocolo declarativo (15 QCIs), Stage-Gate não-compensatório e Índice Euclidiano
│   ├── 06.empirical_validation.tex                # Avaliação Type-1 (Becker R1-R8) e Type-3 (N=30 Chaos Engineering trials)
│   ├── 07.discussion_threats.tex                  # Implicações para AIOps/FinOps e Ameaças à Validade (Wohlin et al.)
│   └── 08.conclusion.tex                          # Síntese das contribuições e diretrizes de Ciência Aberta
├── tables/
│   ├── tbl-existing-models-comparison.tex         # Tabela 1: Comparação crítica com 7 modelos acadêmicos e industriais (Becker R1)
│   ├── tbl-cn-omm-dimensions.tex                  # Tabela 2: As 5 Dimensões Ortogonais, 15 Subcomponentes e regras QCI
│   ├── tbl-cn-omm-matrix.tex                      # Tabela 3: Matriz Arquitetural Completa 5 Níveis x 5 Dimensões do CN-OMM
│   ├── tbl-becker-evaluation.tex                  # Tabela 4: Alinhamento metodológico com os requisitos R1-R8 de Becker et al.
│   └── tbl-empirical-validation.tex               # Tabela 5: Resultados da validação empírica Type-3 (N=30 trials pareados)
├── sigconf.tex                                    # Arquivo LaTeX principal (ACM acmart sigconf)
├── references.bib                                 # Base bibliográfica BibTeX completa e verificada
└── README.md                                      # Este documento
```

---

## Reproduzindo a Avaliação Automatizada e as Figuras do Artigo

Para executar o motor de avaliação do **CN-OMM**, recalcular a tabela de pontuações não-compensatórias (`data/cn_omm_cluster_assessments.csv`), reproduzir todos os testes de hipótese não-paramétricos (*Wilcoxon signed-rank*, *Vargha-Delaney $\hat{A}_{12}$*, *Fisher's exact test*, *One-sample t-test*) e regerar os gráficos vetoriais em PDF:

```bash
python3 scripts/evaluate_cn_omm.py
```

---

## Compilação do Manuscrito LaTeX (ACM `sigconf`)

Para compilar o PDF do artigo localmente via `pdflatex` + `bibtex` ou `latexmk`:

```bash
pdflatex -interaction=nonstopmode sigconf.tex
bibtex sigconf
pdflatex -interaction=nonstopmode sigconf.tex
pdflatex -interaction=nonstopmode sigconf.tex
```

---

## Citação e Licença

Distribuído sob a licença **MIT** (consulte o arquivo `LICENSE`). Caso utilize o modelo **CN-OMM**, os 15 indicadores **QCI** ou os dados experimentais deste pacote, cite o artigo correspondente.
