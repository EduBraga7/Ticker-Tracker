import yfinance as yf
import requests
import os
import sys
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

OPENROUTER_KEY = os.getenv("OPENROUTER_API_KEY")
TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
CHAT_ID = os.getenv("CHAT_ID")

# Carteira com Benchmarks para a IA comparar
CARTEIRA = {
    "📉 BENCHMARKS": ["^BVSP", "IFIX.SA", "USDBRL=X", "^GSPC", "^IXIC"],
    "🏢 AÇÕES BRASILEIRAS": ["SAPR4.SA", "VIVT3.SA", "TAEE11.SA", "BBSE3.SA", "ITSA4.SA", "VALE3.SA", "ISAE4.SA", "BBAS3.SA"],
    "🏘️ FIIs e FIAGROS": ["MXRF11.SA", "VISC11.SA", "BTHF11.SA", "HGLG11.SA", "KNRI11.SA", "VINO11.SA", "SNAG11.SA"],
    "🌎 INTERNACIONAL": ["IVV", "MCD"],
    "🪙 CRIPTOMOEDAS": ["BTC-USD", "ETH-USD"]
}

def processar_dados(periodo_ia):
    lista_visual = ""
    dados_para_ia = ""
    print(f"🔍 Coletando dados e gerando ranking ({periodo_ia})...")
    
    for categoria, ativos in CARTEIRA.items():
        lista_visual += f"\n*{categoria}*\n"
        ativos_coletados = []
        
        for ticker_nome in ativos:
            try:
                t = yf.Ticker(ticker_nome)
                hist = t.history(period="5d") 
                if hist.empty: continue
                
                fechamento = float(hist['Close'].iloc[-1])
                abertura = float(hist['Open'].iloc[-1])
                variacao_dia = ((fechamento / abertura) - 1) * 100
                
                # Coleta variação do período para o "Insight" da IA
                if periodo_ia != "1d":
                    hist_ia = t.history(period=periodo_ia)
                    var_ia = ((hist_ia['Close'].iloc[-1] / hist_ia['Close'].iloc[0]) - 1) * 100
                else:
                    var_ia = variacao_dia

                ativos_coletados.append({
                    "ticker": ticker_nome,
                    "preco": fechamento,
                    "var_dia": variacao_dia,
                    "var_ia": var_ia,
                    "categoria": categoria
                })
            except: continue

        # Ranking por categoria (do melhor para o pior)
        ativos_ordenados = sorted(ativos_coletados, key=lambda x: x['var_dia'], reverse=True)

        for item in ativos_ordenados:
            emoji = "🟩" if item['var_dia'] > 0.05 else "🟥" if item['var_dia'] < -0.05 else "⬜"
            t_nome = item['ticker'].replace(".SA", "")
            
            nicks = {"^BVSP": "IBOV", "IFIX.SA": "IFIX", "USDBRL=X": "DÓLAR", "^GSPC": "S&P 500", "^IXIC": "NASDAQ"}
            final_name = nicks.get(item['ticker'], t_nome)
            
            if item['ticker'] in ["^BVSP", "IFIX.SA", "^GSPC", "^IXIC"]:
                linha = f"{emoji} {final_name}: {item['preco']:,.0f} pts ({item['var_dia']:+.2f}%)"
            elif item['ticker'] == "USDBRL=X":
                linha = f"{emoji} {final_name}: R$ {item['preco']:.2f} ({item['var_dia']:+.2f}%)"
            elif "INTERNACIONAL" in item['categoria'] or "CRIPTO" in item['categoria']:
                linha = f"{emoji} {final_name}: $ {item['preco']:.2f} ({item['var_dia']:+.2f}%)"
            else:
                linha = f"{emoji} {final_name}: R$ {item['preco']:.2f} ({item['var_dia']:+.2f}%)"
            
            lista_visual += f"{linha}\n"
            dados_para_ia += f"{final_name}: {item['var_ia']:+.2f}% | "

    return lista_visual, dados_para_ia

def gerar_insight_ia(dados, tipo):
    if not dados: return "Dados indisponíveis."
    url = "https://openrouter.ai/api/v1/chat/completions"
    
    # Prompt focado em ESTRATÉGIA e INSIGHTS
    config = {
        "DIARIO": "Resumo tático de 3 linhas. Foco no sentimento do dia.",
        "SEMANAL": "Análise de tendência semanal. Destaque os 2 ativos que mais moveram a carteira. Seja incisivo.",
        "MENSAL": "Análise macro sênior. Use termos como drawdown, custo de oportunidade e volatilidade. Mínimo 12 linhas."
    }
    
    prompt_sistema = (
        f"Você é o Estrategista-Chefe da carteira do Eduardo. {config.get(tipo)} "
        "REGRAS: 1. NUNCA use saudações sociais ou assinaturas. 2. Aja como um profissional sênior de mercado. "
        "3. Vá direto ao conteúdo técnico. 4. Use Markdown e emojis."
    )
    
    payload = {
        "model": "google/gemini-2.0-flash-001",
        "messages": [{"role": "system", "content": prompt_sistema}, {"role": "user", "content": f"Performance: {dados}"}],
        "temperature": 0.4
    }
    
    try:
        res = requests.post(url, headers={"Authorization": f"Bearer {OPENROUTER_KEY}"}, json=payload)
        return res.json()['choices'][0]['message']['content']
    except: return "Insights offline."

def main():
    agora = datetime.now()
    
    # Suporte a Modo Teste via Terminal (ex: python script.py MENSAL)
    if len(sys.argv) > 1:
        tipo = sys.argv[1].upper()
    else:
        tipo = "MENSAL" if agora.day == 1 else "SEMANAL" if agora.weekday() == 4 else "DIARIO"

    p_ia = {"DIARIO": "1d", "SEMANAL": "5d", "MENSAL": "30d"}.get(tipo, "1d")

    cabecalho = f"🛡️ *ESTRATÉGIA E INSIGHTS - {agora.strftime('%B / %Y').upper()}*\n"
    cabecalho += f"🗓️ _Gerado em: {agora.strftime('%d/%m/%Y às %H:%M')} ({tipo})_\n\n"

    lista_corpo, dados_ia = processar_dados(p_ia)
    insight = gerar_insight_ia(dados_ia, tipo)
    
    mensagem_final = f"{cabecalho}📝 *ANÁLISE DO ESTRATEGISTA*\n{insight}\n{lista_corpo}"
    
    # Envio direto (Sem frescura de redundância)
    url_tg = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    requests.post(url_tg, json={"chat_id": CHAT_ID, "text": mensagem_final, "parse_mode": "Markdown"})
    
    print(f"✅ Relatório {tipo} enviado com sucesso!")

if __name__ == "__main__":
    main()