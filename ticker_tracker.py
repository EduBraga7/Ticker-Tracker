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

# Carteira oficial
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
    print(f"🔍 Coletando dados para o Eduardo ({periodo_ia})...")
    
    for categoria, ativos in CARTEIRA.items():
        lista_visual += f"\n<b>{categoria}</b>\n"
        ativos_coletados = []
        
        for ticker_nome in ativos:
            try:
                t = yf.Ticker(ticker_nome)
                hist = t.history(period="5d") 
                if hist.empty: continue
                
                fechamento = float(hist['Close'].iloc[-1])
                abertura = float(hist['Open'].iloc[-1])
                variacao_dia = ((fechamento / abertura) - 1) * 100
                
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
    if not dados: return "Sem dados."
    url = "https://openrouter.ai/api/v1/chat/completions"
    
    # Prompts
    contexto = "Eduardo, 25 anos, Buy & Hold, foco em dividendos e longo prazo."
    config = {
        "DIARIO": "Resumo tático de 6 linhas. Sem saudações.",
        "SEMANAL": "Tendência de 5 dias. Aponte oportunidades de aporte no drawdown. 8 linhas.",
        "MENSAL": "Análise macro de 30 dias. Drawdown, juros e estratégia 10 anos. 15 linhas."
    }
    
    prompt = (
        f"Você é o Estrategista-Chefe do {contexto}. {config.get(tipo)} "
        "NÃO use saudações ou assinaturas. Vá direto ao ponto técnico. "
        "REGRA DE OURO: Use tags HTML <b>texto</b> para colocar termos em negrito. "
        "NUNCA use asteriscos (*) ou underscores (_)."
    )
    
    try:
        res = requests.post(url, headers={"Authorization": f"Bearer {OPENROUTER_KEY}"}, 
                            json={"model": "google/gemini-2.0-flash-001", 
                                  "messages": [{"role": "system", "content": prompt}, {"role": "user", "content": f"Dados: {dados}"}],
                                  "temperature": 0.4}, timeout=30)
        return res.json()['choices'][0]['message']['content']
    except: return "Insights indisponíveis. Foco no longo prazo!"

def main():
    agora = datetime.now()
    if len(sys.argv) > 1:
        tipo = sys.argv[1].upper()
    else:
        tipo = "MENSAL" if agora.day == 1 else "SEMANAL" if agora.weekday() == 4 else "DIARIO"

    p_ia = {"DIARIO": "1d", "SEMANAL": "5d", "MENSAL": "30d"}.get(tipo, "1d")

    cabecalho = f"🛡️ <b>ESTRATÉGIA E INSIGHTS - {agora.strftime('%B / %Y').upper()}</b>\n"
    cabecalho += f"<i>Gerado em: {agora.strftime('%d/%m/%Y às %H:%M')} ({tipo})</i>\n\n"

    lista_corpo, dados_ia = processar_dados(p_ia)
    insight = gerar_insight_ia(dados_ia, tipo)
    
    mensagem_final = f"{cabecalho}<b>📝 ANÁLISE DO ESTRATEGISTA</b>\n{insight}\n{lista_corpo}"
    
    url_tg = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    res_tg = requests.post(url_tg, json={"chat_id": CHAT_ID, "text": mensagem_final, "parse_mode": "HTML"})
    
    if res_tg.status_code == 200:
        print(f"✅ Sucesso! Relatório {tipo} enviado em HTML.")
    else:
        print(f"❌ ERRO NO TELEGRAM: {res_tg.status_code} - {res_tg.text}")

if __name__ == "__main__":
    main()