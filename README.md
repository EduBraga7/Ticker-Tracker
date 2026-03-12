<div align="center">
  <img src="assets/logo.png" alt="Logo Ticker-Tracker" width="400">
</div>

# 🛡️ Ticker-Tracker: O Estrategista de Bolso

![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)
![Gemini AI](https://img.shields.io/badge/Gemini%20AI-8E75B2?style=for-the-badge&logo=google-gemini&logoColor=white)

O **Ticker-Tracker** é uma solução de BI (Business Intelligence) automatizada para investidores de longo prazo. Ele fiscaliza o mercado, organiza ativos por performance e utiliza Inteligência Artificial para gerar insights táticos focados na estratégia **Buy & Hold**.

---

## 🚀 Funcionalidades Principais

* **Ranking de Performance:** Ativos organizados automaticamente do melhor para o pior desempenho dentro de cada categoria (Ações, FIIs, Cripto).
* **Análise de Benchmarks:** Comparação em tempo real com IBOV, IFIX, S&P 500, NASDAQ e Dólar.
* **Insight do Estrategista:** Integração com a API do Gemini (via OpenRouter) para análise técnica, focando em oportunidades de aporte, resiliência de carteira e visão de longo prazo.
* **Relatórios Automatizados:** Disparos via Telegram programados para às **18:00 (BRT)** através do GitHub Actions.
* **Robustez Visual:** Formatação em HTML para garantir uma leitura profissional e sem erros de renderização no mobile.

---

## 🛠️ Tech Stack

* **Linguagem:** Python 3.11
* **Dados Financeiros:** `yfinance` (Yahoo Finance API)
* **Inteligência Artificial:** Gemini 2.0 Flash (OpenRouter API)
* **Automação (CI/CD):** GitHub Actions
* **Comunicação:** Telegram Bot API

---

## 🧠 Arquitetura do Sistema

O projeto foi desenhado para ser totalmente *serverless* e econômico:

1.  **Trigger:** O GitHub Actions dispara o ambiente virtual conforme o agendamento (`cron`).
2.  **Extraction:** O script coleta os fechamentos e variações dos ativos em tempo real.
3.  **Processing:** Os dados são filtrados e ordenados. O contexto do investidor (Buy & Hold, reinvestimento de dividendos) é enviado para a IA.
4.  **Delivery:** A análise é enviada via Telegram em um layout scannable e limpo.

---

## ⚙️ Configuração (Setup)

Para rodar este projeto, é necessário configurar as seguintes **Secrets** no repositório do GitHub:

| Secret | Descrição |
| :--- | :--- |
| `OPENROUTER_API_KEY` | Chave de acesso à API do OpenRouter (Gemini). |
| `TELEGRAM_TOKEN` | Token gerado pelo @BotFather. |
| `CHAT_ID` | Seu ID de usuário ou do grupo no Telegram. |

---

## 👨‍💻 Sobre o Autor

**Eduardo Braga**
Estudante de **Análise e Desenvolvimento de Sistemas (ADS)**. Entusiasta de automação, finanças quantitativas e estratégia de acúmulo de patrimônio. Este projeto é a união da tecnologia com a paciência do investidor de valor.

---

> "O mercado financeiro é um mecanismo de transferência de dinheiro dos impacientes para os pacientes." – Warren Buffett
