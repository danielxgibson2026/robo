
//|       PCM_PRO_V7.mq5       
                                      
#property strict
#property version   "1.09"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos;

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+
enum ENUM_DIRECAO_OPERACAO
  {
   DIRECAO_AMBOS = 0,
   DIRECAO_COMPRA = 1,
   DIRECAO_VENDA = 2
  };

enum ENUM_ESTADO_ROBO
  {
   ESTADO_AGUARDANDO_CANAL = 0,
   ESTADO_AGUARDANDO_ROMPIMENTO_CA = 1,
   ESTADO_AGUARDANDO_ROMPIMENTO_C1 = 2,
   ESTADO_OPERADO_DIA = 3,
   ESTADO_AGUARDANDO_PULLBACK = 4,
   ESTADO_LIMITE_DIARIO_ATINGIDO = 5
  };

enum ENUM_QUANTIDADE_TAKES
  {
   TAKES_1 = 1,
   TAKES_2 = 2,
   TAKES_3 = 3
  };

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+
input group "---1. AJUSTES BASICOS---"
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input ENUM_DIRECAO_OPERACAO DirecaoPermitida = DIRECAO_AMBOS;
input long MagicNumber = 88001;
input int HoraInicioSessao = 0;
input int MinutoInicioSessao = 0;
input int HoraLimiteOperacao = 0;
input int MinutoLimiteOperacao = 0;

input group "---2. CANAL DE REFERENCIA---"
input int QuantidadeVelasCanal = 4;
input bool ExpandirCanalAteMinimoPontos = true;
input int MaximoVelasParaExpandirCanal = 20;
input double CanalMinimoPontos = 350.0;
input bool UsarFiltroVelaGrandeCanal = true;
input double TamanhoMaximoVelaCanalPontos = 400.0;
input bool FiltroVelaGrandeCanalUsarCorpo = true;
input double LimiteCanalGrandePontos = 1200.0;
input bool UsarCorpoRealSemPavio = false;
input bool PermitirAjusteManualLinhas = true;
input bool VerificarEntradaAposMoverLinhas = true;
input bool TravarDirecaoNoPrimeiroRompimento = false;
input bool TravarDirecaoPorPavio = false;

input group "---3. FILTRO DE ROMPIMENTO ESTICADO---"
input bool UsarFiltroVelaEsticada = true;
input double PercentualMaximoVelaRompimento = 40.0;
input bool UsarCorpoParaFiltroVela = true;
input bool EntrarNoPullbackAposVelaEsticada = true;
input double BufferPullbackPontos = 200;
input bool MostrarLinhasPullbackVirtual = true;
input bool PullbackSomenteComFechamentoVela = false;
input bool TakeVirtualSomenteComFechamentoVela = false;
input bool MedirLimiteCanalGrandeSomenteCorpo = true;
input double PercentualRompimentoCriarC1 = 5.0;
input double PercentualRompimentoEntrada = 10.0;
input double PercentualMinimoRompimentoValido = 5;

input group "---4. ENTRADAS E SAIDAS---"
input double PercentualStopForaCanal = 10.0;
input double BufferStopPontos = 0.0;
input int MaximoOperacoesPorDia = 30;
input bool ConsiderarVelaFechamentoNaRecriacao = true;
input ENUM_QUANTIDADE_TAKES QuantidadeTakes = TAKES_2;
input double TakeN1Pct = 90.0;
input double TakeN2Pct = 180.0;
input double TakeN3Pct = 270.0;

input group "---5. LOTE---"
input bool UsarLoteDinamico = true;
input double LoteFixo = 0.01;
input double PercentualRiscoBanca = 5.0;

input group "---6. GERENCIAMENTO DIARIO---"
input bool UsarStopDiario = false;
input double StopDiarioPercentual = 5.0;
input bool UsarTakeDiario = false;
input double TakeDiarioPercentual = 5.0;
input bool FecharPosicaoAoAtingirLimiteDiario = false;

input group "---7. ALERTAS---"
input bool AtivarAlertas = true;
input bool AlertaAoCriarCanal = true;
input bool AlertaAoEntrar = true;
input bool AlertaAoTakeStop = true;
input bool AlertaLimiteDiario = true;
input bool UsarSomNosAlertas = true;
input string ArquivoSomAlerta = "alert.wav";

input group "---8. BREAK EVEN---"
input bool UsarBreakEven = false;
input double PercentualRangeTakeParaBreakEven = 70.0;
input double PercentualRangeTakeAposBreakEven = 10;

input group "---9. VISUAL---"
input color CorCanalAbertura = clrDeepSkyBlue;
input color CorCanalC1 = clrOrange;
input color CorTake = clrLime;
input color CorStop = clrRed;
input color CorPullback = clrYellow;
input color CorTakeVirtual = clrMagenta;
input int EspessuraLinhas = 2;
input bool MostrarTextos = true;
input int BotaoDistanciaX = 10;
input int BotaoDistanciaY = 25;

input group "---10. LINHAS DO EQUADOR---"
input bool MostrarLinhasEquador = true;
input int QuantidadeSemanasEquador = 4;
input int QuantidadeExpansoesEquador = 8;
input bool EquadorUsarCorpoSemPavio = true;
input bool MostrarEquadorNivel1 = true;
input bool MostrarEquadorNivel2 = true;
input bool MostrarEquadorNivel3 = true;
input color CorEquadorNivel1 = clrDeepSkyBlue;
input color CorEquadorNivel2 = clrDeepSkyBlue;
input color CorEquadorNivel3 = clrDeepSkyBlue;
input int LarguraEquadorNivel1 = 10;
input int LarguraEquadorNivel2 = 6;
input int LarguraEquadorNivel3 = 2;
input ENUM_LINE_STYLE EstiloEquadorNivel1 = STYLE_SOLID;
input ENUM_LINE_STYLE EstiloEquadorNivel2 = STYLE_SOLID;
input ENUM_LINE_STYLE EstiloEquadorNivel3 = STYLE_SOLID;

input group "---11. MINI EQUADOR / TOPOS E FUNDOS---"
input bool MostrarTopoFundoImportante = false;
input bool MostrarTopoFundoD1 = false;
input bool MostrarTopoFundoH4 = false;
input bool MostrarTopoFundoH1 = false;
input int BarrasAnaliseTopoFundoD1 = 90;
input int BarrasAnaliseTopoFundoH4 = 240;
input int BarrasAnaliseTopoFundoH1 = 480;
input int ForcaSwingTopoFundo = 2;
input int MaxLinhasTopoFundoPorTimeframe = 6;
input color CorTopoFundoD1 = clrRed;
input color CorTopoFundoH4 = clrOrange;
input color CorTopoFundoH1 = clrBlue;
input int LarguraTopoFundo = 1;
input ENUM_LINE_STYLE EstiloTopoFundo = STYLE_DASHDOT;

//+------------------------------------------------------------------+
//| VARIAVEIS GLOBAIS                                                |
//+------------------------------------------------------------------+
ENUM_ESTADO_ROBO Estado = ESTADO_AGUARDANDO_CANAL;

datetime SessaoAtual = 0;
datetime UltimoBarProcessado = 0;

double CA_Topo = 0.0;
double CA_Fundo = 0.0;
double CA_Meio = 0.0;
double CA_Tamanho = 0.0;
double CA_TamanhoCorpo = 0.0;

double C1_Topo = 0.0;
double C1_Fundo = 0.0;
double C1_Meio = 0.0;
datetime CandleCriacaoC1 = 0;

double LinhaTake   = 0.0;
double LinhaTakeN1 = 0.0;
double LinhaTakeN2 = 0.0;
double LinhaTakeN3 = 0.0;
double LinhaStop   = 0.0;

double RangeTakeAtual = 0.0;
double PrecoEntradaAtual = 0.0;

int DirecaoRompimento = 0;
int OperacoesHoje = 0;
bool CanalAtualEhGrande = false;

bool TinhaPosicaoAberta = false;
datetime MomentoFechamentoUltimaOperacao = 0;

// V7: dedupe de reset entre OnTradeTransaction e OnTick.
datetime MomentoUltimoReset = 0;

bool AguardandoPullback = false;
int DirecaoPullback = 0;
double LinhaPullback = 0.0;
double TakeFicticio = 0.0;
double StopFicticio = 0.0;
bool MovimentoEsticadoCancelado = false;
bool PullbackTocado = false;
double MaximaVelaPullback = 0.0;
double MinimaVelaPullback = 0.0;
datetime CandleRompimentoEsticado = 0;
datetime CandlePullbackTocado = 0;
datetime CandleInicioNovaContagem = 0;

double CanalOperacionalTopo = 0.0;
double CanalOperacionalFundo = 0.0;
double CanalOperacionalTamanho = 0.0;
double LinhaRompidaOperacao = 0.0;
int DirecaoC1 = 0;

int PlacarGainDia = 0;
int PlacarLossDia = 0;
int TotalEntradasDia = 0;
double SaldoFinanceiroDia = 0.0;
double ResultadoPontosDia = 0.0;

double SaldoReferenciaDia = 0.0;
double LimitePerdaDiariaValor = 0.0;
double MetaLucroDiariaValor = 0.0;
double ResultadoFinanceiroDiaTotal = 0.0;
bool StopDiarioAtingido = false;
bool TakeDiarioAtingido = false;

string PREFIXO;
string BTN_START;
string BTN_PAINEL;
bool PainelVisivel = true;

#define MAX_LINHAS_PAINEL 60

string OBJ_CA_TOPO;
string OBJ_CA_FUNDO;
string OBJ_CA_MEIO;
string OBJ_C1_TOPO;
string OBJ_C1_FUNDO;
string OBJ_C1_MEIO;
string OBJ_TAKE;
string OBJ_TAKE_N2;
string OBJ_TAKE_N3;
string OBJ_STOP;
string OBJ_PULLBACK;
string OBJ_TAKE_VIRTUAL;
string OBJ_STOP_VIRTUAL;
string TXT_CA;
string TXT_C1;
string TXT_PULLBACK;
string TXT_TAKE_VIRTUAL;
string TXT_STOP_VIRTUAL;
string OBJ_PAINEL_FUNDO;
string OBJ_PAINEL_LINHA_PREFIXO;

int AnoEquadorAtual = 0;
double EquadorTopoBase = 0.0;
double EquadorFundoBase = 0.0;
double EquadorRange = 0.0;
string PREFIXO_EQUADOR;
double DistanciaEquadorN1Pct = 0.0;
double DistanciaEquadorN2Pct = 0.0;
double DistanciaEquadorN3Pct = 0.0;
double PrecoEquadorN1MaisProximo = 0.0;
double PrecoEquadorN2MaisProximo = 0.0;
double PrecoEquadorN3MaisProximo = 0.0;

string PREFIXO_MINI_EQUADOR;
datetime UltimaAtualizacaoD1 = 0;
datetime UltimaAtualizacaoH4 = 0;
datetime UltimaAtualizacaoH1 = 0;

bool BloquearAtualizacaoManual = false;

//+------------------------------------------------------------------+
//| FUNCOES AUXILIARES                                               |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES TF()
  {
   if(Timeframe == PERIOD_CURRENT)
      return (ENUM_TIMEFRAMES)_Period;
   return Timeframe;
  }

double NormalizarPreco(double preco)
  {
   return NormalizeDouble(preco, _Digits);
  }

datetime InicioSessao(datetime tempo)
  {
   MqlDateTime dt;
   TimeToStruct(tempo, dt);
   dt.hour = HoraInicioSessao;
   dt.min = MinutoInicioSessao;
   dt.sec = 0;
   datetime inicio = StructToTime(dt);
   if(tempo < inicio)
      inicio -= 86400;
   return inicio;
  }

bool DentroDoHorarioOperacao()
  {
   if(HoraLimiteOperacao == 0 && MinutoLimiteOperacao == 0)
      return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int minutosAgora   = dt.hour * 60 + dt.min;
   int minutosLimite  = HoraLimiteOperacao * 60 + MinutoLimiteOperacao;
   return minutosAgora < minutosLimite;
  }

bool LimiteDiarioAtingido()
  {
   return StopDiarioAtingido || TakeDiarioAtingido;
  }

bool PodeFazerMaisOperacoes()
  {
   if(LimiteDiarioAtingido())
      return false;
   if(MaximoOperacoesPorDia <= 0)
      return true;
   return OperacoesHoje < MaximoOperacoesPorDia;
  }

datetime MomentoBaseRecriacaoCanais()
  {
   if(ConsiderarVelaFechamentoNaRecriacao)
      return iTime(_Symbol, TF(), 0);
   return TimeCurrent();
  }

bool NovoCandle()
  {
   datetime t = iTime(_Symbol, TF(), 0);
   if(t != UltimoBarProcessado)
     {
      UltimoBarProcessado = t;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| V7 FIX 1: Helpers hedge-safe de posicao                          |
//+------------------------------------------------------------------+
bool SelecionarPosicaoDoRobo(int indice, ulong &ticket)
  {
   ticket = 0;
   int total = PositionsTotal();
   int contador = 0;
   for(int i = 0; i < total; i++)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0)                                              continue;
      if(!PositionSelectByTicket(tk))                          continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)        continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)    continue;
      if(contador == indice) { ticket = tk; return true; }
      contador++;
     }
   return false;
  }

int ContarPosicoesDoRobo()
  {
   int total = PositionsTotal();
   int contador = 0;
   for(int i = 0; i < total; i++)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0)                                              continue;
      if(!PositionSelectByTicket(tk))                          continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)        continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)    continue;
      contador++;
     }
   return contador;
  }

bool ExistePosicaoDoRobo()
  {
   return ContarPosicoesDoRobo() > 0;
  }

double LucroFlutuanteDoRobo()
  {
   double soma = 0.0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0)                                              continue;
      if(!PositionSelectByTicket(tk))                          continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)        continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)    continue;
      soma += PositionGetDouble(POSITION_PROFIT);
      soma += PositionGetDouble(POSITION_SWAP);
     }
   return soma;
  }

//+------------------------------------------------------------------+
//| V7: log de erro ao falhar trade                                  |
//+------------------------------------------------------------------+
void LogarFalhaTrade(string contexto)
  {
   uint   retcode = trade.ResultRetcode();
   string descr   = trade.ResultRetcodeDescription();
   Print("Trade FALHOU [", contexto, "] retcode=", retcode,
         " descr=", descr, " lastError=", GetLastError());
  }

//+------------------------------------------------------------------+
//| OBJETOS GRAFICOS                                                 |
//+------------------------------------------------------------------+
void ApagarObjeto(string nome)
  {
   if(ObjectFind(0, nome) >= 0)
      ObjectDelete(0, nome);
  }

void CriarLinhaHorizontal(string nome, double preco, color cor, ENUM_LINE_STYLE estilo, int largura,
                          bool back, bool selectable, string texto = "")
  {
   ApagarObjeto(nome);
   ObjectCreate(0, nome, OBJ_HLINE, 0, 0, preco);
   ObjectSetInteger(0, nome, OBJPROP_COLOR,      cor);
   ObjectSetInteger(0, nome, OBJPROP_STYLE,      estilo);
   ObjectSetInteger(0, nome, OBJPROP_WIDTH,      largura);
   ObjectSetInteger(0, nome, OBJPROP_BACK,       back);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, nome, OBJPROP_SELECTED,   false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN,     false);
   if(texto != "")
      ObjectSetString(0, nome, OBJPROP_TEXT, texto);
  }

void CriarLinhaH(string nome, double preco, color cor, ENUM_LINE_STYLE estilo, int largura)
  { CriarLinhaHorizontal(nome, preco, cor, estilo, largura, false, true); }

void CriarLinhaEquador(string nome, double preco, color cor, ENUM_LINE_STYLE estilo, int largura)
  { CriarLinhaHorizontal(nome, preco, cor, estilo, largura, true, false); }

void CriarLinhaTopoFundo(string nome, double preco, color cor, ENUM_LINE_STYLE estilo, int largura, string texto)
  { CriarLinhaHorizontal(nome, preco, cor, estilo, largura, true, false, texto); }

void AtualizarLinhaH(string nome, double preco)
  {
   if(ObjectFind(0, nome) >= 0)
      ObjectSetDouble(0, nome, OBJPROP_PRICE, preco);
  }

double LerPrecoLinha(string nome)
  {
   if(ObjectFind(0, nome) < 0)
      return 0.0;
   return ObjectGetDouble(0, nome, OBJPROP_PRICE);
  }

void CriarTexto(string nome, string texto, datetime tempo, double preco, color cor)
  {
   if(!MostrarTextos)
      return;
   ApagarObjeto(nome);
   ObjectCreate(0, nome, OBJ_TEXT, 0, tempo, preco);
   ObjectSetString(0, nome, OBJPROP_TEXT, texto);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, nome, OBJPROP_ANCHOR, ANCHOR_CENTER);
  }

void AtualizarTexto(string nome, datetime tempo, double preco)
  {
   if(ObjectFind(0, nome) >= 0)
      ObjectMove(0, nome, 0, tempo, preco);
  }

void CriarBotao()
  {
   ApagarObjeto(BTN_START);
   ObjectCreate(0, BTN_START, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BTN_START, OBJPROP_XDISTANCE, BotaoDistanciaX);
   ObjectSetInteger(0, BTN_START, OBJPROP_YDISTANCE, BotaoDistanciaY);
   ObjectSetInteger(0, BTN_START, OBJPROP_XSIZE, 80);
   ObjectSetInteger(0, BTN_START, OBJPROP_YSIZE, 28);
   ObjectSetString(0, BTN_START, OBJPROP_TEXT, "INICIAR");
   ObjectSetInteger(0, BTN_START, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, BTN_START, OBJPROP_BGCOLOR, clrDodgerBlue);
   ObjectSetInteger(0, BTN_START, OBJPROP_BORDER_COLOR, clrWhite);
  }

void AtualizarBotaoPainel()
  {
   if(ObjectFind(0, BTN_PAINEL) < 0)
      return;
   ObjectSetString(0, BTN_PAINEL, OBJPROP_TEXT,
                   PainelVisivel ? "OCULTAR PAINEL" : "MOSTRAR PAINEL");
   ObjectSetInteger(0, BTN_PAINEL, OBJPROP_BGCOLOR,
                    PainelVisivel ? clrSlateGray : clrDarkGreen);
  }

void CriarBotaoPainel()
  {
   ApagarObjeto(BTN_PAINEL);
   ObjectCreate(0, BTN_PAINEL, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BTN_PAINEL, OBJPROP_XDISTANCE, BotaoDistanciaX + 90);
   ObjectSetInteger(0, BTN_PAINEL, OBJPROP_YDISTANCE, BotaoDistanciaY);
   ObjectSetInteger(0, BTN_PAINEL, OBJPROP_XSIZE, 125);
   ObjectSetInteger(0, BTN_PAINEL, OBJPROP_YSIZE, 28);
   ObjectSetInteger(0, BTN_PAINEL, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, BTN_PAINEL, OBJPROP_BORDER_COLOR, clrWhite);
   AtualizarBotaoPainel();
  }

void LimparLinhasPullbackVirtual()
  {
   ApagarObjeto(OBJ_PULLBACK);
   ApagarObjeto(OBJ_TAKE_VIRTUAL);
   ApagarObjeto(OBJ_STOP_VIRTUAL);
   ApagarObjeto(TXT_PULLBACK);
   ApagarObjeto(TXT_TAKE_VIRTUAL);
   ApagarObjeto(TXT_STOP_VIRTUAL);
  }

void LimparLinhas()
  {
   ApagarObjeto(OBJ_CA_TOPO);
   ApagarObjeto(OBJ_CA_FUNDO);
   ApagarObjeto(OBJ_CA_MEIO);
   ApagarObjeto(OBJ_C1_TOPO);
   ApagarObjeto(OBJ_C1_FUNDO);
   ApagarObjeto(OBJ_C1_MEIO);
   ApagarObjeto(OBJ_TAKE);
   ApagarObjeto(OBJ_TAKE_N2);
   ApagarObjeto(OBJ_TAKE_N3);
   ApagarObjeto(OBJ_STOP);
   ApagarObjeto(TXT_CA);
   ApagarObjeto(TXT_C1);
   LimparLinhasPullbackVirtual();
  }

void LimparDadosPullbackVirtual()
  {
   AguardandoPullback = false;
   DirecaoPullback = 0;
   LinhaPullback = 0.0;
   TakeFicticio = 0.0;
   StopFicticio = 0.0;
   MovimentoEsticadoCancelado = false;
   PullbackTocado = false;
   MaximaVelaPullback = 0.0;
   MinimaVelaPullback = 0.0;
   CandleRompimentoEsticado = 0;
   CandlePullbackTocado = 0;
  }

void LimparDadosCanais()
  {
   CA_Topo = 0.0;
   CA_Fundo = 0.0;
   CA_Meio = 0.0;
   CA_Tamanho = 0.0;
   C1_Topo = 0.0;
   C1_Fundo = 0.0;
   C1_Meio = 0.0;
   CandleCriacaoC1 = 0;
   LinhaTake   = 0.0;
   LinhaTakeN1 = 0.0;
   LinhaTakeN2 = 0.0;
   LinhaTakeN3 = 0.0;
   LinhaStop   = 0.0;
   RangeTakeAtual    = 0.0;
   PrecoEntradaAtual = 0.0;
   DirecaoRompimento = 0;
   CanalAtualEhGrande = false;
   CanalOperacionalTopo = 0.0;
   CanalOperacionalFundo = 0.0;
   CanalOperacionalTamanho = 0.0;
   LinhaRompidaOperacao = 0.0;
   DirecaoC1 = 0;
   LimparDadosPullbackVirtual();
  }

void InicializarGerenciamentoDiario()
  {
   SaldoReferenciaDia = AccountInfoDouble(ACCOUNT_BALANCE);
   LimitePerdaDiariaValor = SaldoReferenciaDia * StopDiarioPercentual / 100.0;
   MetaLucroDiariaValor = SaldoReferenciaDia * TakeDiarioPercentual / 100.0;
   ResultadoFinanceiroDiaTotal = 0.0;
   StopDiarioAtingido = false;
   TakeDiarioAtingido = false;
  }

void DispararAlerta(string mensagem)
  {
   if(!AtivarAlertas)
      return;
   string texto = _Symbol + " | " + mensagem;
   Alert(texto);
   if(UsarSomNosAlertas && ArquivoSomAlerta != "")
      PlaySound(ArquivoSomAlerta);
  }

void ResetarDia()
  {
   Estado = ESTADO_AGUARDANDO_CANAL;
   LimparDadosCanais();
   OperacoesHoje = 0;
   TinhaPosicaoAberta = false;
   MomentoFechamentoUltimaOperacao = 0;
   MomentoUltimoReset = 0;            // V7: zera dedupe
   CandleInicioNovaContagem = 0;
   InicializarGerenciamentoDiario();
   LimparLinhas();
  }

//+------------------------------------------------------------------+
//| CALCULO DO LOTE                                                  |
//+------------------------------------------------------------------+
double AjustarVolume(double volume)
  {
   double volMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(volume < volMin)  volume = volMin;
   if(volume > volMax)  volume = volMax;
   volume = MathFloor(volume / volStep) * volStep;
   return NormalizeDouble(volume, 2);
  }

//+------------------------------------------------------------------+
//| V7 FIX 4: lote 0 quando risco nao paga volMin                    |
//+------------------------------------------------------------------+
double CalcularLote(double precoEntrada, double precoStop)
  {
   if(!UsarLoteDinamico)
      return AjustarVolume(LoteFixo);

   double riscoDinheiro = AccountInfoDouble(ACCOUNT_EQUITY) * PercentualRiscoBanca / 100.0;
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double volMin    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double distancia = MathAbs(precoEntrada - precoStop);

   if(tickSize <= 0.0 || tickValue <= 0.0 || distancia <= 0.0)
     {
      Print("CalcularLote: dados invalidos. tickSize=", tickSize,
            " tickValue=", tickValue, " distancia=", distancia);
      return 0.0;
     }

   double custoPorLote = distancia / tickSize * tickValue;
   if(custoPorLote <= 0.0)
      return 0.0;

   double lote = riscoDinheiro / custoPorLote;
   if(lote < volMin)
     {
      Print("CalcularLote: risco $", DoubleToString(riscoDinheiro, 2),
            " nao paga volMin=", volMin,
            ". Stop dist=", DoubleToString(distancia / _Point, 1),
            " pts. Entrada ABORTADA.");
      return 0.0;
     }

   return AjustarVolume(lote);
  }
//+------------------------------------------------------------------+
//| CANAIS                                                           |
//+------------------------------------------------------------------+
double TamanhoVelaFiltroCanalPontos(int shift)
  {
   double o = iOpen(_Symbol, TF(), shift);
   double c = iClose(_Symbol, TF(), shift);
   double h = iHigh(_Symbol, TF(), shift);
   double l = iLow(_Symbol, TF(), shift);
   double tamanho = 0.0;
   if(FiltroVelaGrandeCanalUsarCorpo)
      tamanho = MathAbs(c - o);
   else
      tamanho = MathAbs(h - l);
   return tamanho / _Point;
  }

bool VelaGrandeParaCanal(int shift)
  {
   if(!UsarFiltroVelaGrandeCanal)              return false;
   if(TamanhoMaximoVelaCanalPontos <= 0.0)     return false;
   return TamanhoVelaFiltroCanalPontos(shift) > TamanhoMaximoVelaCanalPontos;
  }

bool CalcularCanalPrimeirasVelas(datetime inicio, double &topo, double &fundo)
  {
   int total = iBars(_Symbol, TF());
   if(total <= QuantidadeVelasCanal + 2) return false;

   datetime candleAtual = iTime(_Symbol, TF(), 0);
   int cont = 0;
   topo = -DBL_MAX;
   fundo = DBL_MAX;

   for(int shift = total - 1; shift >= 1; shift--)
     {
      datetime t = iTime(_Symbol, TF(), shift);
      if(t < inicio)        continue;
      if(t >= candleAtual)  continue;

      if(VelaGrandeParaCanal(shift))
        { cont = 0; topo = -DBL_MAX; fundo = DBL_MAX; continue; }

      double o = iOpen(_Symbol, TF(), shift);
      double c = iClose(_Symbol, TF(), shift);
      double h = iHigh(_Symbol, TF(), shift);
      double l = iLow(_Symbol, TF(), shift);

      double maxVela, minVela;
      if(UsarCorpoRealSemPavio) { maxVela = MathMax(o,c); minVela = MathMin(o,c); }
      else                      { maxVela = h;            minVela = l; }

      if(maxVela > topo)  topo  = maxVela;
      if(minVela < fundo) fundo = minVela;

      cont++;
      if(cont >= QuantidadeVelasCanal) break;
     }

   if(cont < QuantidadeVelasCanal) return false;
   if(topo <= fundo)               return false;
   return true;
  }

bool CalcularCanalUltimasVelas(double &topo, double &fundo)
  {
   int total = iBars(_Symbol, TF());
   if(total <= QuantidadeVelasCanal + 2) return false;
   topo = -DBL_MAX;
   fundo = DBL_MAX;
   for(int shift = QuantidadeVelasCanal; shift >= 1; shift--)
     {
      double o = iOpen(_Symbol, TF(), shift);
      double c = iClose(_Symbol, TF(), shift);
      double h = iHigh(_Symbol, TF(), shift);
      double l = iLow(_Symbol, TF(), shift);
      double maxVela, minVela;
      if(UsarCorpoRealSemPavio) { maxVela = MathMax(o,c); minVela = MathMin(o,c); }
      else                      { maxVela = h;            minVela = l; }
      if(maxVela > topo)  topo  = maxVela;
      if(minVela < fundo) fundo = minVela;
     }
   if(topo <= fundo) return false;
   return true;
  }

bool CalcularCanalAposHorario(datetime inicio, double &topo, double &fundo)
  {
   int total = iBars(_Symbol, TF());
   if(total <= QuantidadeVelasCanal + 2) return false;
   datetime candleAtual = iTime(_Symbol, TF(), 0);
   int cont = 0;
   topo = -DBL_MAX;
   fundo = DBL_MAX;
   for(int shift = total - 1; shift >= 1; shift--)
     {
      datetime t = iTime(_Symbol, TF(), shift);
      if(ConsiderarVelaFechamentoNaRecriacao) { if(t < inicio) continue; }
      else                                    { if(t <= inicio) continue; }
      if(t >= candleAtual) continue;
      double o = iOpen(_Symbol, TF(), shift);
      double c = iClose(_Symbol, TF(), shift);
      double h = iHigh(_Symbol, TF(), shift);
      double l = iLow(_Symbol, TF(), shift);
      double maxVela, minVela;
      if(UsarCorpoRealSemPavio) { maxVela = MathMax(o,c); minVela = MathMin(o,c); }
      else                      { maxVela = h;            minVela = l; }
      if(maxVela > topo)  topo  = maxVela;
      if(minVela < fundo) fundo = minVela;
      cont++;
      if(cont >= QuantidadeVelasCanal) break;
     }
   if(cont < QuantidadeVelasCanal) return false;
   if(topo <= fundo)               return false;
   return true;
  }

bool CalcularCanalExpansivoAposHorario(datetime inicio, bool incluirVelaInicio,
                                       double &topo, double &fundo, int &velasUsadas)
  {
   int total = iBars(_Symbol, TF());
   if(total <= QuantidadeVelasCanal + 2) return false;
   datetime candleAtual = iTime(_Symbol, TF(), 0);
   int limiteVelas = QuantidadeVelasCanal;
   if(ExpandirCanalAteMinimoPontos)
      limiteVelas = MathMax(QuantidadeVelasCanal, MaximoVelasParaExpandirCanal);

   if(UsarCorpoRealSemPavio)
     {
      int contCorpo = 0;
      double topoCorpo = -DBL_MAX;
      double fundoCorpo = DBL_MAX;
      for(int shift = total - 1; shift >= 1; shift--)
        {
         datetime t = iTime(_Symbol, TF(), shift);
         if(incluirVelaInicio) { if(t < inicio) continue; }
         else                  { if(t <= inicio) continue; }
         if(t >= candleAtual) continue;
         if(VelaGrandeParaCanal(shift))
           { contCorpo=0; topoCorpo=-DBL_MAX; fundoCorpo=DBL_MAX; continue; }
         double o = iOpen(_Symbol, TF(), shift);
         double c = iClose(_Symbol, TF(), shift);
         double maxCorpo = MathMax(o, c);
         double minCorpo = MathMin(o, c);
         if(maxCorpo > topoCorpo)  topoCorpo  = maxCorpo;
         if(minCorpo < fundoCorpo) fundoCorpo = minCorpo;
         contCorpo++;
         if(contCorpo >= QuantidadeVelasCanal) break;
        }
      if(contCorpo < QuantidadeVelasCanal) return false;
      if(topoCorpo <= fundoCorpo)          return false;
      double tamanhoCorpoPontos = (topoCorpo - fundoCorpo) / _Point;
      if(tamanhoCorpoPontos >= CanalMinimoPontos)
        {
         topo = NormalizarPreco(topoCorpo);
         fundo = NormalizarPreco(fundoCorpo);
         velasUsadas = contCorpo;
         return true;
        }
      if(!ExpandirCanalAteMinimoPontos) return false;

      int contPavio = 0;
      double topoPavio = -DBL_MAX;
      double fundoPavio = DBL_MAX;
      for(int shift = total - 1; shift >= 1; shift--)
        {
         datetime t = iTime(_Symbol, TF(), shift);
         if(incluirVelaInicio) { if(t < inicio) continue; }
         else                  { if(t <= inicio) continue; }
         if(t >= candleAtual) continue;
         if(VelaGrandeParaCanal(shift))
           { contPavio=0; topoPavio=-DBL_MAX; fundoPavio=DBL_MAX; continue; }
         double h = iHigh(_Symbol, TF(), shift);
         double l = iLow(_Symbol, TF(), shift);
         if(h > topoPavio)  topoPavio  = h;
         if(l < fundoPavio) fundoPavio = l;
         contPavio++;
         velasUsadas = contPavio;
         if(contPavio >= QuantidadeVelasCanal)
           {
            double tp = (topoPavio - fundoPavio) / _Point;
            if(tp >= CanalMinimoPontos) break;
           }
         if(contPavio >= limiteVelas) break;
        }
      if(contPavio < QuantidadeVelasCanal) return false;
      if(topoPavio <= fundoPavio)          return false;
      double tamanhoFinal = (topoPavio - fundoPavio) / _Point;
      if(tamanhoFinal < CanalMinimoPontos) return false;
      topo = NormalizarPreco(topoPavio);
      fundo = NormalizarPreco(fundoPavio);
      velasUsadas = contPavio;
      return true;
     }

   int cont = 0;
   topo = -DBL_MAX;
   fundo = DBL_MAX;
   velasUsadas = 0;
   for(int shift = total - 1; shift >= 1; shift--)
     {
      datetime t = iTime(_Symbol, TF(), shift);
      if(incluirVelaInicio) { if(t < inicio) continue; }
      else                  { if(t <= inicio) continue; }
      if(t >= candleAtual) continue;
      if(VelaGrandeParaCanal(shift))
        { cont=0; topo=-DBL_MAX; fundo=DBL_MAX; velasUsadas=0; continue; }
      double h = iHigh(_Symbol, TF(), shift);
      double l = iLow(_Symbol, TF(), shift);
      if(h > topo)  topo  = h;
      if(l < fundo) fundo = l;
      cont++;
      velasUsadas = cont;
      if(cont >= QuantidadeVelasCanal)
        {
         double tp = (topo - fundo) / _Point;
         if(!ExpandirCanalAteMinimoPontos) break;
         if(tp >= CanalMinimoPontos) break;
        }
      if(cont >= limiteVelas) break;
     }
   if(cont < QuantidadeVelasCanal) return false;
   if(topo <= fundo)               return false;
   double tf2 = (topo - fundo) / _Point;
   if(tf2 < CanalMinimoPontos) return false;
   topo = NormalizarPreco(topo);
   fundo = NormalizarPreco(fundo);
   return true;
  }

//+------------------------------------------------------------------+
//| V7 FIX 7: respeita filtro de vela grande igual canal             |
//+------------------------------------------------------------------+
double CalcularTamanhoCorpoPrimeirasVelasApos(datetime inicio)
  {
   int total = iBars(_Symbol, TF());
   if(total <= QuantidadeVelasCanal + 2) return 0.0;
   datetime candleAtual = iTime(_Symbol, TF(), 0);
   int cont = 0;
   double topoCorpo = -DBL_MAX;
   double fundoCorpo = DBL_MAX;
   for(int shift = total - 1; shift >= 1; shift--)
     {
      datetime t = iTime(_Symbol, TF(), shift);
      if(t < inicio)       continue;
      if(t >= candleAtual) continue;
      if(VelaGrandeParaCanal(shift))
        { cont=0; topoCorpo=-DBL_MAX; fundoCorpo=DBL_MAX; continue; }
      double o = iOpen(_Symbol, TF(), shift);
      double c = iClose(_Symbol, TF(), shift);
      double maxCorpo = MathMax(o, c);
      double minCorpo = MathMin(o, c);
      if(maxCorpo > topoCorpo)  topoCorpo  = maxCorpo;
      if(minCorpo < fundoCorpo) fundoCorpo = minCorpo;
      cont++;
      if(cont >= QuantidadeVelasCanal) break;
     }
   if(cont < QuantidadeVelasCanal) return 0.0;
   if(topoCorpo <= fundoCorpo)     return 0.0;
   return NormalizarPreco(topoCorpo) - NormalizarPreco(fundoCorpo);
  }

bool CanalGrandePeloParametro()
  {
   double tamanhoUsado = CA_Tamanho;
   if(MedirLimiteCanalGrandeSomenteCorpo && CA_TamanhoCorpo > 0.0)
      tamanhoUsado = CA_TamanhoCorpo;
   return (tamanhoUsado / _Point) >= LimiteCanalGrandePontos;
  }

void AtualizarCanalOperacional()
  {
   if(C1_Topo > 0.0 && C1_Fundo > 0.0)
     {
      CanalOperacionalTopo = MathMax(CA_Topo, C1_Topo);
      CanalOperacionalFundo = MathMin(CA_Fundo, C1_Fundo);
     }
   else
     {
      CanalOperacionalTopo = CA_Topo;
      CanalOperacionalFundo = CA_Fundo;
     }
   CanalOperacionalTopo = NormalizarPreco(CanalOperacionalTopo);
   CanalOperacionalFundo = NormalizarPreco(CanalOperacionalFundo);
   CanalOperacionalTamanho = CanalOperacionalTopo - CanalOperacionalFundo;
  }

double FiltroRompimentoPontos(double rangeReferencia, double percentual)
  {
   if(rangeReferencia <= 0.0 || percentual <= 0.0) return 0.0;
   return rangeReferencia * percentual / 100.0;
  }

bool RompimentoValidoCompra(double fechamento, double linhaRompida, double rangeReferencia, double percentual)
  {
   if(rangeReferencia <= 0.0) return false;
   double dist = FiltroRompimentoPontos(rangeReferencia, percentual);
   return fechamento >= (linhaRompida + dist);
  }

bool RompimentoValidoVenda(double fechamento, double linhaRompida, double rangeReferencia, double percentual)
  {
   if(rangeReferencia <= 0.0) return false;
   double dist = FiltroRompimentoPontos(rangeReferencia, percentual);
   return fechamento <= (linhaRompida - dist);
  }

bool RompimentoMinimoValidoCompra(double fechamento, double linhaRompida, double rangeReferencia)
  { return RompimentoValidoCompra(fechamento, linhaRompida, rangeReferencia, PercentualMinimoRompimentoValido); }

bool RompimentoMinimoValidoVenda(double fechamento, double linhaRompida, double rangeReferencia)
  { return RompimentoValidoVenda(fechamento, linhaRompida, rangeReferencia, PercentualMinimoRompimentoValido); }

//+------------------------------------------------------------------+
//| EQUADOR                                                          |
//+------------------------------------------------------------------+
void LimparLinhasEquador()
  {
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string nome = ObjectName(0, i, 0, -1);
      if(StringFind(nome, PREFIXO_EQUADOR) == 0)
         ObjectDelete(0, nome);
     }
  }

bool CalcularEquadorAnual()
  {
   if(!MostrarLinhasEquador) return false;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int anoAtual = dt.year;
   if(AnoEquadorAtual == anoAtual && EquadorRange > 0.0) return true;
   double topo = -DBL_MAX;
   double fundo = DBL_MAX;
   int semanasEncontradas = 0;
   int totalW1 = iBars(_Symbol, PERIOD_W1);
   if(totalW1 <= QuantidadeSemanasEquador + 5) return false;
   for(int shift = totalW1 - 1; shift >= 0; shift--)
     {
      datetime tempoSemana = iTime(_Symbol, PERIOD_W1, shift);
      if(tempoSemana <= 0) continue;
      MqlDateTime dtSemana; TimeToStruct(tempoSemana, dtSemana);
      if(dtSemana.year != anoAtual) continue;
      double o = iOpen(_Symbol, PERIOD_W1, shift);
      double c = iClose(_Symbol, PERIOD_W1, shift);
      double h = iHigh(_Symbol, PERIOD_W1, shift);
      double l = iLow(_Symbol, PERIOD_W1, shift);
      double topoVela, fundoVela;
      if(EquadorUsarCorpoSemPavio) { topoVela = MathMax(o,c); fundoVela = MathMin(o,c); }
      else                          { topoVela = h;            fundoVela = l; }
      if(topoVela > topo)   topo  = topoVela;
      if(fundoVela < fundo) fundo = fundoVela;
      semanasEncontradas++;
      if(semanasEncontradas >= QuantidadeSemanasEquador) break;
     }
   if(semanasEncontradas < QuantidadeSemanasEquador) return false;
   if(topo <= fundo) return false;
   EquadorTopoBase  = NormalizarPreco(topo);
   EquadorFundoBase = NormalizarPreco(fundo);
   EquadorRange     = EquadorTopoBase - EquadorFundoBase;
   AnoEquadorAtual  = anoAtual;
   return EquadorRange > 0.0;
  }

void EquadorRangeK(int &inicioK, int &fimK)
  {
   inicioK = -QuantidadeExpansoesEquador * 4;
   fimK    =  4 + (QuantidadeExpansoesEquador * 4);
  }

double EquadorPrecoNivel(int k)
  {
   return NormalizarPreco(EquadorFundoBase + (EquadorRange * 0.25 * k));
  }

void AtualizarDistanciasEquador()
  {
   DistanciaEquadorN1Pct = 0.0;
   DistanciaEquadorN2Pct = 0.0;
   DistanciaEquadorN3Pct = 0.0;
   PrecoEquadorN1MaisProximo = 0.0;
   PrecoEquadorN2MaisProximo = 0.0;
   PrecoEquadorN3MaisProximo = 0.0;
   if(!MostrarLinhasEquador || EquadorRange <= 0.0) return;
   double precoAtual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double menorN1 = DBL_MAX, menorN2 = DBL_MAX, menorN3 = DBL_MAX;
   int inicioK, fimK; EquadorRangeK(inicioK, fimK);
   for(int k = inicioK; k <= fimK; k++)
     {
      double precoLinha = EquadorPrecoNivel(k);
      double dist = MathAbs(precoAtual - precoLinha);
      if(k % 4 == 0)
        { if(dist < menorN1) { menorN1 = dist; PrecoEquadorN1MaisProximo = precoLinha; } }
      else if(k % 2 == 0)
        { if(dist < menorN2) { menorN2 = dist; PrecoEquadorN2MaisProximo = precoLinha; } }
      else
        { if(dist < menorN3) { menorN3 = dist; PrecoEquadorN3MaisProximo = precoLinha; } }
     }
   if(menorN1 < DBL_MAX) DistanciaEquadorN1Pct = menorN1 / EquadorRange * 100.0;
   if(menorN2 < DBL_MAX) DistanciaEquadorN2Pct = menorN2 / EquadorRange * 100.0;
   if(menorN3 < DBL_MAX) DistanciaEquadorN3Pct = menorN3 / EquadorRange * 100.0;
  }

void DesenharEquadorCompleto()
  {
   if(!MostrarLinhasEquador) { LimparLinhasEquador(); return; }
   if(!CalcularEquadorAnual()) return;
   LimparLinhasEquador();
   int inicioK, fimK; EquadorRangeK(inicioK, fimK);
   for(int k = inicioK; k <= fimK; k++)
     {
      double preco = EquadorPrecoNivel(k);
      bool ehN1 = (k % 4 == 0);
      bool ehN2 = (!ehN1 && k % 2 == 0);
      bool ehN3 = (!ehN1 && !ehN2);
      if(ehN1 && !MostrarEquadorNivel1) continue;
      if(ehN2 && !MostrarEquadorNivel2) continue;
      if(ehN3 && !MostrarEquadorNivel3) continue;
      string nivel = "N3_";
      color cor = CorEquadorNivel3;
      ENUM_LINE_STYLE estilo = EstiloEquadorNivel3;
      int largura = LarguraEquadorNivel3;
      if(ehN1)      { nivel="N1_"; cor=CorEquadorNivel1; estilo=EstiloEquadorNivel1; largura=LarguraEquadorNivel1; }
      else if(ehN2) { nivel="N2_"; cor=CorEquadorNivel2; estilo=EstiloEquadorNivel2; largura=LarguraEquadorNivel2; }
      string nome = PREFIXO_EQUADOR + nivel + IntegerToString(k);
      CriarLinhaEquador(nome, preco, cor, estilo, largura);
     }
   AtualizarDistanciasEquador();
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| MINI EQUADOR / TOPOS-FUNDOS                                      |
//+------------------------------------------------------------------+
void LimparLinhasMiniEquador()
  {
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string nome = ObjectName(0, i, 0, -1);
      if(StringFind(nome, PREFIXO_MINI_EQUADOR) == 0)
         ObjectDelete(0, nome);
     }
  }

void LimparLinhasMiniEquadorTF(string tagTF)
  {
   string prefixoTF = PREFIXO_MINI_EQUADOR + tagTF + "_";
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string nome = ObjectName(0, i, 0, -1);
      if(StringFind(nome, prefixoTF) == 0) ObjectDelete(0, nome);
     }
  }

bool PrecoJaMarcado(double preco, double &lista[], int total, double toleranciaPontos)
  {
   for(int i = 0; i < total; i++)
      if(MathAbs(preco - lista[i]) <= toleranciaPontos * _Point) return true;
   return false;
  }

bool EhTopoSwing(ENUM_TIMEFRAMES tf, int shift, int forca)
  {
   double h = iHigh(_Symbol, tf, shift);
   if(h <= 0.0) return false;
   for(int i = 1; i <= forca; i++)
     {
      if(iHigh(_Symbol, tf, shift - i) >= h) return false;
      if(iHigh(_Symbol, tf, shift + i) > h)  return false;
     }
   return true;
  }

bool EhFundoSwing(ENUM_TIMEFRAMES tf, int shift, int forca)
  {
   double l = iLow(_Symbol, tf, shift);
   if(l <= 0.0) return false;
   for(int i = 1; i <= forca; i++)
     {
      if(iLow(_Symbol, tf, shift - i) <= l) return false;
      if(iLow(_Symbol, tf, shift + i) < l)  return false;
     }
   return true;
  }

void DesenharTopoFundoTimeframe(ENUM_TIMEFRAMES tf, string tagTF, int barrasAnalise, color cor)
  {
   if(!MostrarTopoFundoImportante) return;
   LimparLinhasMiniEquadorTF(tagTF);
   int totalBarras = iBars(_Symbol, tf);
   if(totalBarras <= ForcaSwingTopoFundo * 2 + 10) return;
   int maxShift = MathMin(barrasAnalise, totalBarras - ForcaSwingTopoFundo - 2);
   int linhasCriadas = 0;
   double precosMarcados[];
   ArrayResize(precosMarcados, MaxLinhasTopoFundoPorTimeframe * 2 + 10);
   int totalMarcados = 0;
   for(int shift = ForcaSwingTopoFundo + 1; shift <= maxShift; shift++)
     {
      if(linhasCriadas >= MaxLinhasTopoFundoPorTimeframe) break;
      if(EhTopoSwing(tf, shift, ForcaSwingTopoFundo))
        {
         double p = NormalizarPreco(iHigh(_Symbol, tf, shift));
         if(!PrecoJaMarcado(p, precosMarcados, totalMarcados, 20.0))
           {
            precosMarcados[totalMarcados++] = p;
            string nome = PREFIXO_MINI_EQUADOR + tagTF + "_TOPO_" + IntegerToString(linhasCriadas);
            CriarLinhaTopoFundo(nome, p, cor, EstiloTopoFundo, LarguraTopoFundo, tagTF + " TOPO");
            linhasCriadas++;
           }
        }
      if(linhasCriadas >= MaxLinhasTopoFundoPorTimeframe) break;
      if(EhFundoSwing(tf, shift, ForcaSwingTopoFundo))
        {
         double p = NormalizarPreco(iLow(_Symbol, tf, shift));
         if(!PrecoJaMarcado(p, precosMarcados, totalMarcados, 20.0))
           {
            precosMarcados[totalMarcados++] = p;
            string nome = PREFIXO_MINI_EQUADOR + tagTF + "_FUNDO_" + IntegerToString(linhasCriadas);
            CriarLinhaTopoFundo(nome, p, cor, EstiloTopoFundo, LarguraTopoFundo, tagTF + " FUNDO");
            linhasCriadas++;
           }
        }
     }
  }

void DesenharMiniEquadorTopoFundo()
  {
   if(!MostrarTopoFundoImportante) { LimparLinhasMiniEquador(); return; }
   if(MostrarTopoFundoD1) DesenharTopoFundoTimeframe(PERIOD_D1, "D1", BarrasAnaliseTopoFundoD1, CorTopoFundoD1);
   else                    LimparLinhasMiniEquadorTF("D1");
   if(MostrarTopoFundoH4) DesenharTopoFundoTimeframe(PERIOD_H4, "H4", BarrasAnaliseTopoFundoH4, CorTopoFundoH4);
   else                    LimparLinhasMiniEquadorTF("H4");
   if(MostrarTopoFundoH1) DesenharTopoFundoTimeframe(PERIOD_H1, "H1", BarrasAnaliseTopoFundoH1, CorTopoFundoH1);
   else                    LimparLinhasMiniEquadorTF("H1");
   ChartRedraw();
  }

void AtualizarMiniEquadorSeNecessario()
  {
   if(!MostrarTopoFundoImportante) return;
   bool atualizar = false;
   datetime tD1 = iTime(_Symbol, PERIOD_D1, 0);
   datetime tH4 = iTime(_Symbol, PERIOD_H4, 0);
   datetime tH1 = iTime(_Symbol, PERIOD_H1, 0);
   if(tD1 != UltimaAtualizacaoD1) { UltimaAtualizacaoD1 = tD1; atualizar = true; }
   if(tH4 != UltimaAtualizacaoH4) { UltimaAtualizacaoH4 = tH4; atualizar = true; }
   if(tH1 != UltimaAtualizacaoH1) { UltimaAtualizacaoH1 = tH1; atualizar = true; }
   if(atualizar) DesenharMiniEquadorTopoFundo();
  }

//+------------------------------------------------------------------+
//| DESENHO DOS CANAIS                                               |
//+------------------------------------------------------------------+
void DesenharCanalAbertura()
  {
   CA_Meio = (CA_Topo + CA_Fundo) / 2.0;
   CriarLinhaH(OBJ_CA_TOPO,  CA_Topo,  CorCanalAbertura, STYLE_SOLID, EspessuraLinhas);
   CriarLinhaH(OBJ_CA_FUNDO, CA_Fundo, CorCanalAbertura, STYLE_SOLID, EspessuraLinhas);
   CriarLinhaH(OBJ_CA_MEIO,  CA_Meio,  CorCanalAbertura, STYLE_DOT,   1);
   datetime tempoTexto = iTime(_Symbol, TF(), 0);
   CriarTexto(TXT_CA, "CA", tempoTexto, CA_Meio, CorCanalAbertura);
   ChartRedraw();
  }

bool FormarCanalAutomatico()
  {
   if(!PodeFazerMaisOperacoes()) return false;
   double topo, fundo;
   int velasUsadas = 0;
   bool okCanal = false;
   if(ExpandirCanalAteMinimoPontos)
      okCanal = CalcularCanalExpansivoAposHorario(SessaoAtual, true, topo, fundo, velasUsadas);
   else
      okCanal = CalcularCanalPrimeirasVelas(SessaoAtual, topo, fundo);
   if(!okCanal) return false;
   double tamanhoPontos = (topo - fundo) / _Point;
   if(tamanhoPontos < CanalMinimoPontos) return false;
   CA_Topo = NormalizarPreco(topo);
   CA_Fundo = NormalizarPreco(fundo);
   CA_Tamanho = CA_Topo - CA_Fundo;
   CA_TamanhoCorpo = CA_Tamanho;
   if(MedirLimiteCanalGrandeSomenteCorpo)
     {
      double corpoCalc = CalcularTamanhoCorpoPrimeirasVelasApos(SessaoAtual);
      if(corpoCalc > 0.0) CA_TamanhoCorpo = corpoCalc;
     }
   CanalAtualEhGrande = CanalGrandePeloParametro();
   AtualizarCanalOperacional();
   DesenharCanalAbertura();
   if(AlertaAoCriarCanal)
      DispararAlerta("Canal criado: " + DoubleToString(CA_Tamanho / _Point, 1) + " pts");
   Estado = ESTADO_AGUARDANDO_ROMPIMENTO_CA;
   return true;
  }

bool FormarNovoCanalAposFechamento()
  {
   if(MomentoFechamentoUltimaOperacao <= 0) return false;
   double topo, fundo;
   int velasUsadas = 0;
   datetime baseContagem = MomentoFechamentoUltimaOperacao;
   bool incluirInicio = ConsiderarVelaFechamentoNaRecriacao;
   if(CandleInicioNovaContagem > 0)
     { baseContagem = CandleInicioNovaContagem; incluirInicio = false; }
   bool okCanal = false;
   if(ExpandirCanalAteMinimoPontos || CandleInicioNovaContagem > 0)
      okCanal = CalcularCanalExpansivoAposHorario(baseContagem, incluirInicio, topo, fundo, velasUsadas);
   else
      okCanal = CalcularCanalAposHorario(baseContagem, topo, fundo);
   if(!okCanal) return false;
   double tamanhoPontos = (topo - fundo) / _Point;
   if(tamanhoPontos < CanalMinimoPontos) return false;
   CA_Topo = NormalizarPreco(topo);
   CA_Fundo = NormalizarPreco(fundo);
   CA_Tamanho = CA_Topo - CA_Fundo;
   CA_TamanhoCorpo = CA_Tamanho;
   if(MedirLimiteCanalGrandeSomenteCorpo)
     {
      double corpoCalc = CalcularTamanhoCorpoPrimeirasVelasApos(baseContagem);
      if(corpoCalc > 0.0) CA_TamanhoCorpo = corpoCalc;
     }
   CanalAtualEhGrande = CanalGrandePeloParametro();
   AtualizarCanalOperacional();
   DesenharCanalAbertura();
   if(AlertaAoCriarCanal)
      DispararAlerta("Canal criado: " + DoubleToString(CA_Tamanho / _Point, 1) + " pts");
   Estado = ESTADO_AGUARDANDO_ROMPIMENTO_CA;
   CandleInicioNovaContagem = 0;
   return true;
  }

//+------------------------------------------------------------------+
//| V7 FIX 3: bloqueia INICIAR se houver posicao ou pullback         |
//+------------------------------------------------------------------+
bool FormarCanalManual()
  {
   if(ExistePosicaoDoRobo())
     {
      DispararAlerta("INICIAR bloqueado: posicao aberta. Feche antes.");
      return false;
     }
   if(AguardandoPullback)
     {
      DispararAlerta("INICIAR bloqueado: aguardando pullback.");
      return false;
     }
   if(!PodeFazerMaisOperacoes()) return false;

   double topo, fundo;
   if(!CalcularCanalUltimasVelas(topo, fundo)) return false;
   double tamanhoPontos = (topo - fundo) / _Point;
   if(tamanhoPontos < CanalMinimoPontos) return false;

   CA_Topo = NormalizarPreco(topo);
   CA_Fundo = NormalizarPreco(fundo);
   CA_Tamanho = CA_Topo - CA_Fundo;
   CA_TamanhoCorpo = CA_Tamanho;

   if(!MedirLimiteCanalGrandeSomenteCorpo)
     {
      double topoCorpo  = -DBL_MAX;
      double fundoCorpo =  DBL_MAX;
      for(int shift = QuantidadeVelasCanal; shift >= 1; shift--)
        {
         double o = iOpen(_Symbol, TF(), shift);
         double c = iClose(_Symbol, TF(), shift);
         if(MathMax(o,c) > topoCorpo)  topoCorpo  = MathMax(o,c);
         if(MathMin(o,c) < fundoCorpo) fundoCorpo = MathMin(o,c);
        }
      if(topoCorpo > fundoCorpo)
         CA_TamanhoCorpo = NormalizarPreco(topoCorpo) - NormalizarPreco(fundoCorpo);
     }

   CanalAtualEhGrande = CanalGrandePeloParametro();
   DirecaoRompimento = 0;
   MomentoFechamentoUltimaOperacao = 0;
   LimparDadosPullbackVirtual();
   LimparLinhas();
   DesenharCanalAbertura();
   if(AlertaAoCriarCanal)
      DispararAlerta("Canal criado: " + DoubleToString(CA_Tamanho / _Point, 1) + " pts");
   Estado = ESTADO_AGUARDANDO_ROMPIMENTO_CA;
   return true;
  }

void RecalcularC1PorCanalAtual()
  {
   if(Estado != ESTADO_AGUARDANDO_ROMPIMENTO_C1) return;
   if(DirecaoRompimento == 1)
     { C1_Fundo = CA_Topo; C1_Topo = CA_Topo + CA_Tamanho; }
   else if(DirecaoRompimento == -1)
     { C1_Topo = CA_Fundo; C1_Fundo = CA_Fundo - CA_Tamanho; }
   else return;
   C1_Topo = NormalizarPreco(C1_Topo);
   C1_Fundo = NormalizarPreco(C1_Fundo);
   C1_Meio = (C1_Topo + C1_Fundo) / 2.0;
   AtualizarLinhaH(OBJ_C1_TOPO, C1_Topo);
   AtualizarLinhaH(OBJ_C1_FUNDO, C1_Fundo);
   AtualizarLinhaH(OBJ_C1_MEIO, C1_Meio);
   datetime tempoTexto = iTime(_Symbol, TF(), 0);
   AtualizarTexto(TXT_C1, tempoTexto, C1_Meio);
  }

bool AtualizarCanalPorLinhasManuais()
  {
   if(BloquearAtualizacaoManual) return false;
   if(!PermitirAjusteManualLinhas) return false;
   if(Estado < ESTADO_AGUARDANDO_ROMPIMENTO_CA) return false;
   double topoLinha = LerPrecoLinha(OBJ_CA_TOPO);
   double fundoLinha = LerPrecoLinha(OBJ_CA_FUNDO);
   if(topoLinha <= 0.0 || fundoLinha <= 0.0) return false;
   if(topoLinha < fundoLinha)
     { double tmp = topoLinha; topoLinha = fundoLinha; fundoLinha = tmp; }
   double novoTopo = NormalizarPreco(topoLinha);
   double novoFundo = NormalizarPreco(fundoLinha);
   bool mudou = (MathAbs(novoTopo - CA_Topo) > (_Point * 0.5) ||
                 MathAbs(novoFundo - CA_Fundo) > (_Point * 0.5));
   if(!mudou) return false;
   CA_Topo = novoTopo;
   CA_Fundo = novoFundo;
   CA_Tamanho = CA_Topo - CA_Fundo;
   CA_TamanhoCorpo = CA_Tamanho;
   CanalAtualEhGrande = CanalGrandePeloParametro();
   CA_Meio = (CA_Topo + CA_Fundo) / 2.0;
   BloquearAtualizacaoManual = true;
   AtualizarLinhaH(OBJ_CA_TOPO,  CA_Topo);
   AtualizarLinhaH(OBJ_CA_FUNDO, CA_Fundo);
   AtualizarLinhaH(OBJ_CA_MEIO,  CA_Meio);
   BloquearAtualizacaoManual = false;
   datetime tempoTexto = iTime(_Symbol, TF(), 0);
   AtualizarTexto(TXT_CA, tempoTexto, CA_Meio);
   RecalcularC1PorCanalAtual();
   AtualizarCanalOperacional();
   ChartRedraw();
   return true;
  }

void CriarCanalC1(int direcao)
  {
   DirecaoRompimento = direcao;
   DirecaoC1 = direcao;
   if(direcao == 1)
     { C1_Fundo = CA_Topo; C1_Topo = CA_Topo + CA_Tamanho; }
   else if(direcao == -1)
     { C1_Topo = CA_Fundo; C1_Fundo = CA_Fundo - CA_Tamanho; }
   C1_Topo = NormalizarPreco(C1_Topo);
   C1_Fundo = NormalizarPreco(C1_Fundo);
   C1_Meio = (C1_Topo + C1_Fundo) / 2.0;
   CriarLinhaH(OBJ_C1_TOPO,  C1_Topo,  CorCanalC1, STYLE_SOLID, EspessuraLinhas);
   CriarLinhaH(OBJ_C1_FUNDO, C1_Fundo, CorCanalC1, STYLE_SOLID, EspessuraLinhas);
   CriarLinhaH(OBJ_C1_MEIO,  C1_Meio,  CorCanalC1, STYLE_DOT,   1);
   datetime tempoTexto = iTime(_Symbol, TF(), 0);
   CriarTexto(TXT_C1, "C1", tempoTexto, C1_Meio, CorCanalC1);
   CandleCriacaoC1 = iTime(_Symbol, TF(), 1);
   AtualizarCanalOperacional();
   Estado = ESTADO_AGUARDANDO_ROMPIMENTO_C1;
   ChartRedraw();
  }

void CalcularNiveisTake(int direcao, double baseTake, double rangeExpansao)
  {
   double dN1 = rangeExpansao * (TakeN1Pct / 100.0);
   double dN2 = dN1 * 2.0;
   double dN3 = dN1 * 3.0;
   if(direcao == 1)
     {
      LinhaTakeN1 = NormalizarPreco(baseTake + dN1);
      LinhaTakeN2 = NormalizarPreco(baseTake + dN2);
      LinhaTakeN3 = NormalizarPreco(baseTake + dN3);
     }
   else
     {
      LinhaTakeN1 = NormalizarPreco(baseTake - dN1);
      LinhaTakeN2 = NormalizarPreco(baseTake - dN2);
      LinhaTakeN3 = NormalizarPreco(baseTake - dN3);
     }
   LinhaTake = LinhaTakeN1;
   RangeTakeAtual = dN1;
  }

bool PodeComprar() { return DirecaoPermitida == DIRECAO_AMBOS || DirecaoPermitida == DIRECAO_COMPRA; }
bool PodeVender() { return DirecaoPermitida == DIRECAO_AMBOS || DirecaoPermitida == DIRECAO_VENDA; }

void DesenharTakeStop()
  {
   CriarLinhaH(OBJ_TAKE, LinhaTake, CorTake, STYLE_DASH, 1);
   if((int)QuantidadeTakes >= 2 && LinhaTakeN2 > 0.0)
      CriarLinhaH(OBJ_TAKE_N2, LinhaTakeN2, CorTake, STYLE_DOT, 1);
   else
      ApagarObjeto(OBJ_TAKE_N2);
   if((int)QuantidadeTakes >= 3 && LinhaTakeN3 > 0.0)
      CriarLinhaH(OBJ_TAKE_N3, LinhaTakeN3, CorTake, STYLE_DOT, 1);
   else
      ApagarObjeto(OBJ_TAKE_N3);
   CriarLinhaH(OBJ_STOP, LinhaStop, CorStop, STYLE_DASH, 1);
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| ENTRADAS (V7: protege com lote 0 + log de erro)                  |
//+------------------------------------------------------------------+
void ExecutarCompra()
  {
   if(!PodeComprar())               return;
   if(ExistePosicaoDoRobo())        return;
   if(!DentroDoHorarioOperacao())   return;
   if(!PodeFazerMaisOperacoes())    return;

   AtualizarCanalOperacional();
   if(CanalOperacionalTamanho <= 0.0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double margemStop = CanalOperacionalTamanho * PercentualStopForaCanal / 100.0;
   LinhaStop = CanalOperacionalFundo - margemStop - BufferStopPontos * _Point;
   double linhaBaseTake = LinhaRompidaOperacao;
   if(linhaBaseTake <= 0.0) linhaBaseTake = CanalOperacionalTopo;
   CalcularNiveisTake(1, linhaBaseTake, CanalOperacionalTamanho);
   LinhaStop = NormalizarPreco(LinhaStop);

   double lote = CalcularLote(ask, LinhaStop);
   if(lote <= 0.0)
     {
      DispararAlerta("COMPRA abortada: lote 0 (ver log).");
      return;
     }

   DesenharTakeStop();
   LimparLinhasPullbackVirtual();
   LimparDadosPullbackVirtual();

   bool ok = trade.Buy(lote, _Symbol, 0.0, LinhaStop, LinhaTake, "FIMATHE COMPRA");
   if(ok)
     {
      OperacoesHoje++;
      TinhaPosicaoAberta = true;
      PrecoEntradaAtual = ask;
      Estado = ESTADO_OPERADO_DIA;
      if(AlertaAoEntrar)
         DispararAlerta("Entrada de COMPRA realizada em " + DoubleToString(ask, _Digits));
     }
   else
     {
      LogarFalhaTrade("Buy");
     }
  }

void ExecutarVenda()
  {
   if(!PodeVender())               return;
   if(ExistePosicaoDoRobo())       return;
   if(!DentroDoHorarioOperacao())  return;
   if(!PodeFazerMaisOperacoes())   return;

   AtualizarCanalOperacional();
   if(CanalOperacionalTamanho <= 0.0) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double margemStop = CanalOperacionalTamanho * PercentualStopForaCanal / 100.0;
   LinhaStop = CanalOperacionalTopo + margemStop + BufferStopPontos * _Point;
   double linhaBaseTake = LinhaRompidaOperacao;
   if(linhaBaseTake <= 0.0) linhaBaseTake = CanalOperacionalFundo;
   CalcularNiveisTake(-1, linhaBaseTake, CanalOperacionalTamanho);
   LinhaStop = NormalizarPreco(LinhaStop);

   double lote = CalcularLote(bid, LinhaStop);
   if(lote <= 0.0)
     {
      DispararAlerta("VENDA abortada: lote 0 (ver log).");
      return;
     }

   DesenharTakeStop();
   LimparLinhasPullbackVirtual();
   LimparDadosPullbackVirtual();

   bool ok = trade.Sell(lote, _Symbol, 0.0, LinhaStop, LinhaTake, "FIMATHE VENDA");
   if(ok)
     {
      OperacoesHoje++;
      TinhaPosicaoAberta = true;
      PrecoEntradaAtual = bid;
      Estado = ESTADO_OPERADO_DIA;
      if(AlertaAoEntrar)
         DispararAlerta("Entrada de VENDA realizada em " + DoubleToString(bid, _Digits));
     }
   else
     {
      LogarFalhaTrade("Sell");
     }
  }

//+------------------------------------------------------------------+
//| FILTRO VELA ESTICADA E PULLBACK                                  |
//+------------------------------------------------------------------+
bool VelaRompimentoEsticada(int shift, double rangeReferencia)
  {
   if(!UsarFiltroVelaEsticada) return false;
   if(rangeReferencia <= 0.0)  return false;
   double open  = iOpen(_Symbol, TF(), shift);
   double close = iClose(_Symbol, TF(), shift);
   double high  = iHigh(_Symbol, TF(), shift);
   double low   = iLow(_Symbol, TF(), shift);
   double tamanhoVela = 0.0;
   if(UsarCorpoParaFiltroVela) tamanhoVela = MathAbs(close - open);
   else                         tamanhoVela = MathAbs(high - low);
   double percentual = tamanhoVela / rangeReferencia * 100.0;
   return percentual > PercentualMaximoVelaRompimento;
  }

double CalcularStopVirtualCompra()
  {
   double margemStop = CA_Tamanho * PercentualStopForaCanal / 100.0;
   double extremoInferiorStop = CA_Fundo;
   if(C1_Fundo > 0.0 && C1_Fundo < extremoInferiorStop) extremoInferiorStop = C1_Fundo;
   return NormalizarPreco(extremoInferiorStop - margemStop - BufferStopPontos * _Point);
  }

double CalcularStopVirtualVenda()
  {
   double margemStop = CA_Tamanho * PercentualStopForaCanal / 100.0;
   double extremoSuperiorStop = CA_Topo;
   if(C1_Topo > 0.0 && C1_Topo > extremoSuperiorStop) extremoSuperiorStop = C1_Topo;
   return NormalizarPreco(extremoSuperiorStop + margemStop + BufferStopPontos * _Point);
  }

void DesenharPullbackVirtual()
  {
   if(!MostrarLinhasPullbackVirtual) return;
   CriarLinhaH(OBJ_PULLBACK,     LinhaPullback, CorPullback,    STYLE_DASHDOT, 1);
   CriarLinhaH(OBJ_TAKE_VIRTUAL, TakeFicticio,  CorTakeVirtual, STYLE_DOT,     1);
   ApagarObjeto(OBJ_STOP_VIRTUAL);
   datetime tempoTexto = iTime(_Symbol, TF(), 0);
   CriarTexto(TXT_PULLBACK,     "PULLBACK",     tempoTexto, LinhaPullback, CorPullback);
   CriarTexto(TXT_TAKE_VIRTUAL, "TAKE VIRTUAL", tempoTexto, TakeFicticio,  CorTakeVirtual);
   ApagarObjeto(TXT_STOP_VIRTUAL);
   ChartRedraw();
  }

void IniciarEsperaPullback(int direcao, double linhaRetorno, double takeFake)
  {
   if(!EntrarNoPullbackAposVelaEsticada)
     {
      MomentoFechamentoUltimaOperacao = MomentoBaseRecriacaoCanais();
      LimparLinhas();
      LimparDadosCanais();
      Estado = ESTADO_AGUARDANDO_CANAL;
      return;
     }
   AguardandoPullback = true;
   PullbackTocado = false;
   DirecaoPullback = direcao;
   LinhaPullback = NormalizarPreco(linhaRetorno);
   TakeFicticio = NormalizarPreco(takeFake);
   StopFicticio = 0.0;
   MovimentoEsticadoCancelado = false;
   MaximaVelaPullback = 0.0;
   MinimaVelaPullback = 0.0;
   CandleRompimentoEsticado = iTime(_Symbol, TF(), 1);
   CandlePullbackTocado = 0;
   Estado = ESTADO_AGUARDANDO_PULLBACK;
   DesenharPullbackVirtual();
  }

void CancelarPullbackVoltarEsperaOperacao()
  {
   MovimentoEsticadoCancelado = true;
   AguardandoPullback = false;
   PullbackTocado = false;
   DirecaoPullback = 0;
   LinhaPullback = 0.0;
   TakeFicticio = 0.0;
   StopFicticio = 0.0;
   MaximaVelaPullback = 0.0;
   MinimaVelaPullback = 0.0;
   CandleRompimentoEsticado = 0;
   CandlePullbackTocado = 0;
   LimparLinhasPullbackVirtual();
   if(LimiteDiarioAtingido())
      Estado = ESTADO_LIMITE_DIARIO_ATINGIDO;
   else if(PodeFazerMaisOperacoes())
     {
      AtualizarCanalOperacional();
      Estado = (C1_Topo > 0.0 && C1_Fundo > 0.0)
               ? ESTADO_AGUARDANDO_ROMPIMENTO_C1
               : ESTADO_AGUARDANDO_ROMPIMENTO_CA;
     }
   else
      Estado = ESTADO_OPERADO_DIA;
  }

void ResetarPorTakeVirtual()
  {
   MovimentoEsticadoCancelado = true;
   datetime candleFechado = iTime(_Symbol, TF(), 1);
   if(CandleRompimentoEsticado > 0 && candleFechado == CandleRompimentoEsticado)
     {
      MomentoFechamentoUltimaOperacao = CandleRompimentoEsticado;
      CandleInicioNovaContagem = CandleRompimentoEsticado;
     }
   else
     {
      MomentoFechamentoUltimaOperacao = MomentoBaseRecriacaoCanais();
      CandleInicioNovaContagem = 0;
     }
   LimparLinhas();
   LimparDadosCanais();
   if(LimiteDiarioAtingido())
      Estado = ESTADO_LIMITE_DIARIO_ATINGIDO;
   else if(PodeFazerMaisOperacoes())
      Estado = ESTADO_AGUARDANDO_CANAL;
   else
      Estado = ESTADO_OPERADO_DIA;
  }

void VerificarPullbackAposVelaEsticada()
  {
   if(!AguardandoPullback)    return;
   if(ExistePosicaoDoRobo())  return;

   double close1 = iClose(_Symbol, TF(), 1);
   double high1  = iHigh(_Symbol, TF(), 1);
   double low1   = iLow(_Symbol, TF(), 1);
   datetime candleFechado = iTime(_Symbol, TF(), 1);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(close1 <= 0.0) return;

   if(DirecaoPullback == 1)
     {
      bool atingiuTakeVirtual = false;
      if(TakeVirtualSomenteComFechamentoVela)
         atingiuTakeVirtual = (close1 >= TakeFicticio);
      else
         atingiuTakeVirtual = (bid >= TakeFicticio || high1 >= TakeFicticio);
      if(atingiuTakeVirtual) { ResetarPorTakeVirtual(); return; }

      if(!PullbackTocado)
        {
         bool tocou = false;
         if(PullbackSomenteComFechamentoVela)
            tocou = (close1 <= LinhaPullback - BufferPullbackPontos * _Point);
         else
            tocou = (bid <= LinhaPullback - BufferPullbackPontos * _Point ||
                     low1 <= LinhaPullback - BufferPullbackPontos * _Point);
         if(tocou)
           {
            PullbackTocado = true;
            CandlePullbackTocado = candleFechado;
            MaximaVelaPullback = high1;
            MinimaVelaPullback = low1;
            return;
           }
        }
      else
        {
         if(candleFechado <= CandlePullbackTocado) return;
         bool confirmou = (close1 > LinhaRompidaOperacao);
         if(confirmou)
           {
            AguardandoPullback = false;
            PullbackTocado = false;
            DirecaoPullback = 0;
            LimparLinhasPullbackVirtual();
            ExecutarCompra();
            return;
           }
         CancelarPullbackVoltarEsperaOperacao();
         return;
        }
     }
   else if(DirecaoPullback == -1)
     {
      bool atingiuTakeVirtual = false;
      if(TakeVirtualSomenteComFechamentoVela)
         atingiuTakeVirtual = (close1 <= TakeFicticio);
      else
         atingiuTakeVirtual = (ask <= TakeFicticio || low1 <= TakeFicticio);
      if(atingiuTakeVirtual) { ResetarPorTakeVirtual(); return; }

      if(!PullbackTocado)
        {
         bool tocou = false;
         if(PullbackSomenteComFechamentoVela)
            tocou = (close1 >= LinhaPullback + BufferPullbackPontos * _Point);
         else
            tocou = (ask >= LinhaPullback + BufferPullbackPontos * _Point ||
                     high1 >= LinhaPullback + BufferPullbackPontos * _Point);
         if(tocou)
           {
            PullbackTocado = true;
            CandlePullbackTocado = candleFechado;
            MaximaVelaPullback = high1;
            MinimaVelaPullback = low1;
            return;
           }
        }
      else
        {
         if(candleFechado <= CandlePullbackTocado) return;
         bool confirmou = (close1 < LinhaRompidaOperacao);
         if(confirmou)
           {
            AguardandoPullback = false;
            PullbackTocado = false;
            DirecaoPullback = 0;
            LimparLinhasPullbackVirtual();
            ExecutarVenda();
            return;
           }
         CancelarPullbackVoltarEsperaOperacao();
         return;
        }
     }
  }

void ProcessarEntradaCompraComFiltro(double linhaRetorno, double takeFake, double rangeReferencia)
  {
   if(VelaRompimentoEsticada(1, rangeReferencia))
     {
      IniciarEsperaPullback(1, linhaRetorno, takeFake);
      return;
     }
   ExecutarCompra();
  }

void ProcessarEntradaVendaComFiltro(double linhaRetorno, double takeFake, double rangeReferencia)
  {
   if(VelaRompimentoEsticada(1, rangeReferencia))
     {
      IniciarEsperaPullback(-1, linhaRetorno, takeFake);
      return;
     }
   ExecutarVenda();
  }

//+------------------------------------------------------------------+
//| LOGICA DE ROMPIMENTO                                             |
//+------------------------------------------------------------------+
void VerificarRompimentoCanalAbertura()
  {
   if(Estado != ESTADO_AGUARDANDO_ROMPIMENTO_CA) return;
   double close1 = iClose(_Symbol, TF(), 1);
   double high1  = iHigh(_Symbol, TF(), 1);
   double low1   = iLow(_Symbol, TF(), 1);
   if(close1 <= 0.0) return;
   bool canalGrande = CanalAtualEhGrande;
   AtualizarCanalOperacional();
   bool rompeuCompra = false, rompeuVenda = false;
   if(TravarDirecaoPorPavio)
     {
      if(high1 > CA_Topo)  rompeuCompra = true;
      if(low1 < CA_Fundo)  rompeuVenda  = true;
     }
   else
     {
      if(close1 > CA_Topo)  rompeuCompra = true;
      if(close1 < CA_Fundo) rompeuVenda  = true;
     }
   if(TravarDirecaoNoPrimeiroRompimento)
     {
      if(DirecaoRompimento == 1)  rompeuVenda  = false;
      if(DirecaoRompimento == -1) rompeuCompra = false;
     }
   if(rompeuCompra)
     {
      if(!PodeComprar()) return;
      if(!canalGrande)
        {
         if(!RompimentoValidoCompra(close1, CA_Topo, CA_Tamanho, PercentualRompimentoCriarC1)) return;
         DirecaoRompimento = 1;
         CriarCanalC1(1);
         return;
        }
      if(!RompimentoValidoCompra(close1, CA_Topo, CA_Tamanho, PercentualRompimentoEntrada)) return;
      DirecaoRompimento = 1;
      LinhaRompidaOperacao = CA_Topo;
      AtualizarCanalOperacional();
      double takeFake = LinhaRompidaOperacao + (CanalOperacionalTamanho * (TakeN1Pct / 100.0));
      ProcessarEntradaCompraComFiltro(LinhaRompidaOperacao, takeFake, CanalOperacionalTamanho);
      return;
     }
   if(rompeuVenda)
     {
      if(!PodeVender()) return;
      if(!canalGrande)
        {
         if(!RompimentoValidoVenda(close1, CA_Fundo, CA_Tamanho, PercentualRompimentoCriarC1)) return;
         DirecaoRompimento = -1;
         CriarCanalC1(-1);
         return;
        }
      if(!RompimentoValidoVenda(close1, CA_Fundo, CA_Tamanho, PercentualRompimentoEntrada)) return;
      DirecaoRompimento = -1;
      LinhaRompidaOperacao = CA_Fundo;
      AtualizarCanalOperacional();
      double takeFake = LinhaRompidaOperacao - (CanalOperacionalTamanho * (TakeN1Pct / 100.0));
      ProcessarEntradaVendaComFiltro(LinhaRompidaOperacao, takeFake, CanalOperacionalTamanho);
      return;
     }
  }

void VerificarRompimentoC1()
  {
   if(Estado != ESTADO_AGUARDANDO_ROMPIMENTO_C1) return;
   double close1 = iClose(_Symbol, TF(), 1);
   datetime candleFechado = iTime(_Symbol, TF(), 1);
   if(close1 <= 0.0) return;
   AtualizarCanalOperacional();
   if(CanalOperacionalTamanho <= 0.0) return;
   bool mesmoCandleCriacaoC1 = (candleFechado == CandleCriacaoC1);
   if(mesmoCandleCriacaoC1) return;
   if(close1 > CanalOperacionalTopo)
     {
      if(!PodeComprar()) return;
      if(!RompimentoValidoCompra(close1, CanalOperacionalTopo, CanalOperacionalTamanho, PercentualRompimentoEntrada)) return;
      LinhaRompidaOperacao = CanalOperacionalTopo;
      double takeFake = LinhaRompidaOperacao + (CanalOperacionalTamanho * (TakeN1Pct / 100.0));
      ProcessarEntradaCompraComFiltro(LinhaRompidaOperacao, takeFake, CanalOperacionalTamanho);
      return;
     }
   if(close1 < CanalOperacionalFundo)
     {
      if(!PodeVender()) return;
      if(!RompimentoValidoVenda(close1, CanalOperacionalFundo, CanalOperacionalTamanho, PercentualRompimentoEntrada)) return;
      LinhaRompidaOperacao = CanalOperacionalFundo;
      double takeFake = LinhaRompidaOperacao - (CanalOperacionalTamanho * (TakeN1Pct / 100.0));
      ProcessarEntradaVendaComFiltro(LinhaRompidaOperacao, takeFake, CanalOperacionalTamanho);
      return;
     }
  }

void ProcessarRompimentosAposAjusteManual()
  {
   if(!VerificarEntradaAposMoverLinhas) return;
   if(ExistePosicaoDoRobo()) return;
   if(AguardandoPullback)    return;
   if(Estado == ESTADO_AGUARDANDO_ROMPIMENTO_CA)
      VerificarRompimentoCanalAbertura();
   else if(Estado == ESTADO_AGUARDANDO_ROMPIMENTO_C1)
      VerificarRompimentoC1();
  }

//+------------------------------------------------------------------+
//| V7 FIX 2: dedupe contra reset duplo (OnTrade + OnTick)           |
//+------------------------------------------------------------------+
void AplicarResetPosOperacao()
  {
   datetime agora = TimeCurrent();
   if(MomentoUltimoReset > 0 && (agora - MomentoUltimoReset) <= 3)
      return;
   MomentoUltimoReset = agora;
   MomentoFechamentoUltimaOperacao = MomentoBaseRecriacaoCanais();
   LimparLinhas();
   LimparDadosCanais();
   if(LimiteDiarioAtingido())
      Estado = ESTADO_LIMITE_DIARIO_ATINGIDO;
   else if(PodeFazerMaisOperacoes())
      Estado = ESTADO_AGUARDANDO_CANAL;
   else
      Estado = ESTADO_OPERADO_DIA;
  }

void VerificarFechamentoOperacao()
  {
   bool temPosicaoAgora = ExistePosicaoDoRobo();
   if(TinhaPosicaoAberta && !temPosicaoAgora)
      AplicarResetPosOperacao();
   TinhaPosicaoAberta = temPosicaoAgora;
  }

//+------------------------------------------------------------------+
//| BREAK EVEN (V7: hedge-safe + BUY aceita SL=0)                    |
//+------------------------------------------------------------------+
void GerenciarBreakEven()
  {
   if(!UsarBreakEven) return;
   if(RangeTakeAtual <= 0.0) return;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double distAtivacao = RangeTakeAtual * PercentualRangeTakeParaBreakEven / 100.0;
   double distGarantia = RangeTakeAtual * PercentualRangeTakeAposBreakEven / 100.0;
   int totalPos = ContarPosicoesDoRobo();
   for(int idx = 0; idx < totalPos; idx++)
     {
      ulong ticket = 0;
      if(!SelecionarPosicaoDoRobo(idx, ticket)) continue;
      if(!PositionSelectByTicket(ticket))       continue;
      long   tipo         = PositionGetInteger(POSITION_TYPE);
      double precoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
      double slAtual      = PositionGetDouble(POSITION_SL);
      double tpAtual      = PositionGetDouble(POSITION_TP);
      if(tipo == POSITION_TYPE_BUY)
        {
         double lucroPreco = bid - precoEntrada;
         if(lucroPreco >= distAtivacao)
           {
            double novoSL = NormalizarPreco(precoEntrada + distGarantia);
            if(slAtual == 0.0 || slAtual < novoSL)
              {
               if(!trade.PositionModify(ticket, novoSL, tpAtual))
                  LogarFalhaTrade("BE BUY ticket=" + IntegerToString((long)ticket));
              }
           }
        }
      else if(tipo == POSITION_TYPE_SELL)
        {
         double lucroPreco = precoEntrada - ask;
         if(lucroPreco >= distAtivacao)
           {
            double novoSL = NormalizarPreco(precoEntrada - distGarantia);
            if(slAtual == 0.0 || slAtual > novoSL)
              {
               if(!trade.PositionModify(ticket, novoSL, tpAtual))
                  LogarFalhaTrade("BE SELL ticket=" + IntegerToString((long)ticket));
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| GERENCIAMENTO DIARIO E PLACAR                                    |
//+------------------------------------------------------------------+
void AtualizarPlacarDiario()
  {
   PlacarGainDia = 0;
   PlacarLossDia = 0;
   TotalEntradasDia = 0;
   SaldoFinanceiroDia = 0.0;
   ResultadoPontosDia = 0.0;
   datetime inicio = SessaoAtual;
   datetime fim = TimeCurrent();
   if(!HistorySelect(inicio, fim)) return;
   int totalDeals = HistoryDealsTotal();
   ulong  entryPosIds[];
   double entryPrecos[];
   long   entryTipos[];
   int    entryCount = 0;
   ArrayResize(entryPosIds, totalDeals);
   ArrayResize(entryPrecos, totalDeals);
   ArrayResize(entryTipos,  totalDeals);
   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_IN) continue;
      entryPosIds[entryCount] = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
      entryPrecos[entryCount] = HistoryDealGetDouble(ticket, DEAL_PRICE);
      entryTipos[entryCount]  = HistoryDealGetInteger(ticket, DEAL_TYPE);
      entryCount++;
     }
   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber) continue;
      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      long type  = HistoryDealGetInteger(ticket, DEAL_TYPE);
      if(entry != DEAL_ENTRY_OUT) continue;
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL) continue;
      double profit     = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      double swap       = HistoryDealGetDouble(ticket, DEAL_SWAP);
      double resultadoLiquido = profit + commission + swap;
      SaldoFinanceiroDia += resultadoLiquido;
      TotalEntradasDia++;
      if(resultadoLiquido > 0.0)      PlacarGainDia++;
      else if(resultadoLiquido < 0.0) PlacarLossDia++;
      double precoSaida = HistoryDealGetDouble(ticket, DEAL_PRICE);
      ulong  positionId = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
      double precoEntrada = 0.0;
      long   tipoEntrada  = -1;
      for(int j = 0; j < entryCount; j++)
        {
         if(entryPosIds[j] == positionId)
           {
            precoEntrada = entryPrecos[j];
            tipoEntrada  = entryTipos[j];
            break;
           }
        }
      if(precoEntrada > 0.0)
        {
         double pontos = 0.0;
         if(tipoEntrada == DEAL_TYPE_BUY)       pontos = (precoSaida - precoEntrada) / _Point;
         else if(tipoEntrada == DEAL_TYPE_SELL) pontos = (precoEntrada - precoSaida) / _Point;
         ResultadoPontosDia += pontos;
        }
     }
  }

void AtualizarResultadoFinanceiroDiaTotal()
  {
   AtualizarPlacarDiario();
   ResultadoFinanceiroDiaTotal = SaldoFinanceiroDia + LucroFlutuanteDoRobo();
  }

void GerenciarLimitesDiarios()
  {
   if(LimiteDiarioAtingido()) return;
   if(SaldoReferenciaDia <= 0.0) InicializarGerenciamentoDiario();
   AtualizarResultadoFinanceiroDiaTotal();
   bool atingiuStop = (UsarStopDiario && StopDiarioPercentual > 0.0 &&
                       ResultadoFinanceiroDiaTotal <= -LimitePerdaDiariaValor);
   bool atingiuTake = (UsarTakeDiario && TakeDiarioPercentual > 0.0 &&
                       ResultadoFinanceiroDiaTotal >= MetaLucroDiariaValor);
   if(!atingiuStop && !atingiuTake) return;
   if(atingiuStop) StopDiarioAtingido = true;
   else            TakeDiarioAtingido = true;
   if(AlertaLimiteDiario)
     {
      if(StopDiarioAtingido)
         DispararAlerta("STOP DIARIO atingido: " + DoubleToString(ResultadoFinanceiroDiaTotal, 2));
      else
         DispararAlerta("TAKE DIARIO atingido: " + DoubleToString(ResultadoFinanceiroDiaTotal, 2));
     }
   if(FecharPosicaoAoAtingirLimiteDiario && ExistePosicaoDoRobo())
     {
      // V7: fecha TODAS as posicoes do robo (hedge-safe)
      int totalPos = ContarPosicoesDoRobo();
      for(int idx = 0; idx < totalPos; idx++)
        {
         ulong tk = 0;
         if(SelecionarPosicaoDoRobo(idx, tk))
            if(!trade.PositionClose(tk))
               LogarFalhaTrade("Close ticket=" + IntegerToString((long)tk));
        }
     }
   LimparLinhasPullbackVirtual();
   LimparDadosPullbackVirtual();
   Estado = ESTADO_LIMITE_DIARIO_ATINGIDO;
  }

//+------------------------------------------------------------------+
//| PAINEL                                                           |
//+------------------------------------------------------------------+
void LimparLinhasPainelAntigas(int qtd)
  {
   for(int i = 0; i < qtd; i++)
     {
      string nome = OBJ_PAINEL_LINHA_PREFIXO + IntegerToString(i);
      if(ObjectFind(0, nome) >= 0) ObjectDelete(0, nome);
     }
  }

void CriarOuAtualizarTextoPainel(int indice, string texto, int x, int y, color cor, int tamanhoFonte)
  {
   string nome = OBJ_PAINEL_LINHA_PREFIXO + IntegerToString(indice);
   if(ObjectFind(0, nome) < 0)
     {
      ObjectCreate(0, nome, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nome, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
      ObjectSetString(0, nome, OBJPROP_FONT, "Consolas");
     }
   ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_FONTSIZE, tamanhoFonte);
   ObjectSetString(0, nome, OBJPROP_TEXT, texto);
  }

void DesenharFundoPainel(int altura)
  {
   if(ObjectFind(0, OBJ_PAINEL_FUNDO) < 0)
     {
      ObjectCreate(0, OBJ_PAINEL_FUNDO, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_COLOR, clrDimGray);
      ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_BACK, false);
      ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_HIDDEN, true);
     }
   ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_YDISTANCE, 58);
   ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_XSIZE, 220);
   ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_YSIZE, altura);
   ObjectSetInteger(0, OBJ_PAINEL_FUNDO, OBJPROP_BGCOLOR, clrBlack);
  }

void MostrarStatus()
  {
   if(!PainelVisivel)
     {
      LimparLinhasPainelAntigas(MAX_LINHAS_PAINEL);
      ApagarObjeto(OBJ_PAINEL_FUNDO);
      Comment("");
      ChartRedraw();
      return;
     }
   AtualizarResultadoFinanceiroDiaTotal();
   string estadoTxt = "";
   if(Estado == ESTADO_AGUARDANDO_CANAL)              estadoTxt = "Aguardando formar CA";
   else if(Estado == ESTADO_AGUARDANDO_ROMPIMENTO_CA) estadoTxt = "Aguardando rompimento CA";
   else if(Estado == ESTADO_AGUARDANDO_ROMPIMENTO_C1) estadoTxt = "Aguardando rompimento C1";
   else if(Estado == ESTADO_OPERADO_DIA)              estadoTxt = "Limite de operacoes atingido";
   else if(Estado == ESTADO_AGUARDANDO_PULLBACK)      estadoTxt = "Aguardando pullback";
   else if(Estado == ESTADO_LIMITE_DIARIO_ATINGIDO)
     {
      if(StopDiarioAtingido)      estadoTxt = "Stop diario atingido";
      else if(TakeDiarioAtingido) estadoTxt = "Take diario atingido";
     }
   string direcaoTxt = "Nenhuma";
   if(DirecaoRompimento == 1)       direcaoTxt = "Compra";
   else if(DirecaoRompimento == -1) direcaoTxt = "Venda";
   string horarioLimiteTxt = "Sem limite";
   if(HoraLimiteOperacao != 0 || MinutoLimiteOperacao != 0)
     {
      horarioLimiteTxt = StringFormat("%02d:%02d", HoraLimiteOperacao, MinutoLimiteOperacao);
      if(!DentroDoHorarioOperacao()) horarioLimiteTxt += " (ENCERRADO)";
     }
   int x = 15, y = 66, passo = 18, fonte = 10, linha = 0;
   color corTexto = clrWhite;
   color corTitulo = clrAqua;
   color corPlacar = clrGold;
   color corSaldo = clrLime;
   color corNegativo = clrTomato;
   LimparLinhasPainelAntigas(MAX_LINHAS_PAINEL);
   CriarOuAtualizarTextoPainel(linha++, "FIMATHE PCM PRO V7", x, y, corTitulo, 12); y += passo + 2;
   CriarOuAtualizarTextoPainel(linha++, "Estado: " + estadoTxt, x, y, corTexto, fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Direcao: " + direcaoTxt, x, y, corTexto, fonte); y += passo;
   string opsTxt = IntegerToString(OperacoesHoje);
   if(MaximoOperacoesPorDia > 0) opsTxt += "/" + IntegerToString(MaximoOperacoesPorDia);
   else                          opsTxt += " (sem limite)";
   CriarOuAtualizarTextoPainel(linha++, "Operacoes hoje: " + opsTxt, x, y,
                               (PodeFazerMaisOperacoes() ? corTexto : clrTomato), fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Horario limite: " + horarioLimiteTxt, x, y,
                               (DentroDoHorarioOperacao() ? corTexto : clrTomato), fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Saldo ref. dia: " + DoubleToString(SaldoReferenciaDia, 2), x, y, corTexto, fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Resultado dia total: " + DoubleToString(ResultadoFinanceiroDiaTotal, 2), x, y,
                               (ResultadoFinanceiroDiaTotal >= 0.0 ? clrLime : clrTomato), fonte); y += passo;
   string stopDiarioTxt = UsarStopDiario ? (DoubleToString(StopDiarioPercentual, 2) + "% = " + DoubleToString(LimitePerdaDiariaValor, 2)) : "DESATIVADO";
   string takeDiarioTxt = UsarTakeDiario ? (DoubleToString(TakeDiarioPercentual, 2) + "% = " + DoubleToString(MetaLucroDiariaValor, 2)) : "DESATIVADO";
   CriarOuAtualizarTextoPainel(linha++, "Stop diario: " + stopDiarioTxt, x, y, (StopDiarioAtingido ? clrTomato : corTexto), fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Take diario: " + takeDiarioTxt, x, y, (TakeDiarioAtingido ? clrLime   : corTexto), fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Status diario: " + (LimiteDiarioAtingido() ? "BLOQUEADO" : "LIBERADO"), x, y,
                               (LimiteDiarioAtingido() ? clrTomato : clrLime), fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "------------------------------", x, y, clrSilver, fonte); y += passo;
   if(CA_Tamanho > 0.0)
     {
      CriarOuAtualizarTextoPainel(linha++, "Canal abertura: " + DoubleToString(CA_Tamanho / _Point, 1) + " pts", x, y, corTexto, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "CA corpo limite: " + DoubleToString(CA_TamanhoCorpo / _Point, 1) + " pts", x, y, corTexto, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "Canal grande: " + (CanalAtualEhGrande ? "SIM" : "NAO"), x, y,
                                  (CanalAtualEhGrande ? clrOrange : clrLime), fonte); y += passo;
     }
   else
     { CriarOuAtualizarTextoPainel(linha++, "Canal abertura: aguardando", x, y, corTexto, fonte); y += passo; }
   if(C1_Topo > 0.0 && C1_Fundo > 0.0)
      CriarOuAtualizarTextoPainel(linha++, "Canal C1: " + DoubleToString((C1_Topo - C1_Fundo) / _Point, 1) + " pts", x, y, corTexto, fonte);
   else
      CriarOuAtualizarTextoPainel(linha++, "Canal C1: nao criado", x, y, clrSilver, fonte);
   y += passo;
   if(LinhaTakeN1 > 0.0)
     {
      CriarOuAtualizarTextoPainel(linha++, "Take N1: " + DoubleToString(LinhaTakeN1, _Digits) +
                                  " (" + DoubleToString(TakeN1Pct, 1) + ")", x, y, CorTake, fonte); y += passo;
      if((int)QuantidadeTakes >= 2 && LinhaTakeN2 > 0.0)
        {
         CriarOuAtualizarTextoPainel(linha++, "Take N2: " + DoubleToString(LinhaTakeN2, _Digits) +
                                     " (" + DoubleToString(TakeN1Pct * 2.0, 1) + ")", x, y, CorTake, fonte); y += passo;
        }
      if((int)QuantidadeTakes >= 3 && LinhaTakeN3 > 0.0)
        {
         CriarOuAtualizarTextoPainel(linha++, "Take N3: " + DoubleToString(LinhaTakeN3, _Digits) +
                                     " (" + DoubleToString(TakeN1Pct * 3.0, 1) + ")", x, y, CorTake, fonte); y += passo;
        }
      if(RangeTakeAtual > 0.0)
        {
         CriarOuAtualizarTextoPainel(linha++, "Range take: " + DoubleToString(RangeTakeAtual / _Point, 1) + " pts", x, y, clrSilver, fonte); y += passo;
        }
     }
   if(AguardandoPullback)
     {
      CriarOuAtualizarTextoPainel(linha++, "Pullback: AGUARDANDO", x, y, clrYellow, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "Linha pullback: " + DoubleToString(LinhaPullback, _Digits), x, y, clrYellow, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "Confirmacao: " + (PullbackTocado ? "AGUARDANDO RETOMADA" : "AGUARDANDO TOQUE"), x, y, clrYellow, fonte); y += passo;
     }
   if(UsarBreakEven && RangeTakeAtual > 0.0)
     {
      CriarOuAtualizarTextoPainel(linha++, "------------------------------", x, y, clrSilver, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "BREAK EVEN", x, y, clrAqua, 11); y += passo;
      double ptosAtivacao = RangeTakeAtual * PercentualRangeTakeParaBreakEven / 100.0 / _Point;
      double ptosGarantia = RangeTakeAtual * PercentualRangeTakeAposBreakEven / 100.0 / _Point;
      CriarOuAtualizarTextoPainel(linha++, "Ativa em: " + DoubleToString(ptosAtivacao, 0) + " pts (" +
                                  DoubleToString(PercentualRangeTakeParaBreakEven, 0) + "% range)", x, y, corTexto, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "Garante: " + DoubleToString(ptosGarantia, 0) + " pts (" +
                                  DoubleToString(PercentualRangeTakeAposBreakEven, 0) + "% range)", x, y, corTexto, fonte); y += passo;
     }
   CriarOuAtualizarTextoPainel(linha++, "------------------------------", x, y, clrSilver, fonte); y += passo;
   if(MostrarLinhasEquador && EquadorRange > 0.0)
     {
      CriarOuAtualizarTextoPainel(linha++, "EQUADOR", x, y, clrAqua, 11); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "N1 prox: " + DoubleToString(DistanciaEquadorN1Pct, 1) + "%", x, y, CorEquadorNivel1, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "N2 prox: " + DoubleToString(DistanciaEquadorN2Pct, 1) + "%", x, y, CorEquadorNivel2, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "N3 prox: " + DoubleToString(DistanciaEquadorN3Pct, 1) + "%", x, y, CorEquadorNivel3, fonte); y += passo;
      CriarOuAtualizarTextoPainel(linha++, "------------------------------", x, y, clrSilver, fonte); y += passo;
     }
   CriarOuAtualizarTextoPainel(linha++, "PLACAR DO DIA", x, y, corPlacar, 11); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Entradas: " + IntegerToString(TotalEntradasDia), x, y, corPlacar, fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Gains: "    + IntegerToString(PlacarGainDia),    x, y, clrLime,    fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Losses: "   + IntegerToString(PlacarLossDia),    x, y, clrTomato,  fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Resultado pontos: " + DoubleToString(ResultadoPontosDia, 1), x, y,
                               (ResultadoPontosDia >= 0.0 ? clrLime : clrTomato), fonte); y += passo;
   CriarOuAtualizarTextoPainel(linha++, "Saldo do dia: " + DoubleToString(SaldoFinanceiroDia, 2), x, y,
                               (SaldoFinanceiroDia >= 0.0 ? corSaldo : corNegativo), 11); y += passo;
   int altura = (y - 58) + 12;
   DesenharFundoPainel(altura);
   Comment("");
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| EVENTOS                                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   PREFIXO = "FIMATHE_" + _Symbol + "_" + IntegerToString((int)MagicNumber) + "_";
   PREFIXO_EQUADOR = PREFIXO + "EQUADOR_";
   PREFIXO_MINI_EQUADOR = PREFIXO + "MINI_EQ_";
   BTN_START = PREFIXO + "BTN_START";
   BTN_PAINEL = PREFIXO + "BTN_PAINEL";
   OBJ_CA_TOPO = PREFIXO + "CA_TOPO";
   OBJ_CA_FUNDO = PREFIXO + "CA_FUNDO";
   OBJ_CA_MEIO = PREFIXO + "CA_MEIO";
   OBJ_C1_TOPO = PREFIXO + "C1_TOPO";
   OBJ_C1_FUNDO = PREFIXO + "C1_FUNDO";
   OBJ_C1_MEIO = PREFIXO + "C1_MEIO";
   OBJ_TAKE    = PREFIXO + "TAKE";
   OBJ_TAKE_N2 = PREFIXO + "TAKE_N2";
   OBJ_TAKE_N3 = PREFIXO + "TAKE_N3";
   OBJ_STOP    = PREFIXO + "STOP";
   OBJ_PULLBACK = PREFIXO + "PULLBACK";
   OBJ_TAKE_VIRTUAL = PREFIXO + "TAKE_VIRTUAL";
   OBJ_STOP_VIRTUAL = PREFIXO + "STOP_VIRTUAL";
   TXT_CA = PREFIXO + "TXT_CA";
   TXT_C1 = PREFIXO + "TXT_C1";
   TXT_PULLBACK = PREFIXO + "TXT_PULLBACK";
   TXT_TAKE_VIRTUAL = PREFIXO + "TXT_TAKE_VIRTUAL";
   TXT_STOP_VIRTUAL = PREFIXO + "TXT_STOP_VIRTUAL";
   OBJ_PAINEL_FUNDO = PREFIXO + "PAINEL_FUNDO";
   OBJ_PAINEL_LINHA_PREFIXO = PREFIXO + "PAINEL_LINHA_";

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);

   SessaoAtual = InicioSessao(TimeCurrent());
   CriarBotao();
   CriarBotaoPainel();
   ResetarDia();
   DesenharEquadorCompleto();
   DesenharMiniEquadorTopoFundo();
   TinhaPosicaoAberta = ExistePosicaoDoRobo();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason) { Comment(""); }

void PrepararRecriacaoAposFechamento()
  {
   AplicarResetPosOperacao();
   TinhaPosicaoAberta = ExistePosicaoDoRobo();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   ulong deal = trans.deal;
   if(deal == 0) return;
   if(!HistoryDealSelect(deal)) return;
   string symbol = HistoryDealGetString(deal, DEAL_SYMBOL);
   long magic = HistoryDealGetInteger(deal, DEAL_MAGIC);
   long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
   long type = HistoryDealGetInteger(deal, DEAL_TYPE);
   long reason = HistoryDealGetInteger(deal, DEAL_REASON);
   if(symbol != _Symbol)         return;
   if(magic != MagicNumber)      return;
   if(entry != DEAL_ENTRY_OUT)   return;
   if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL) return;
   if(AlertaAoTakeStop)
     {
      if(reason == DEAL_REASON_TP)      DispararAlerta("TAKE atingido");
      else if(reason == DEAL_REASON_SL) DispararAlerta("STOP atingido");
     }
   PrepararRecriacaoAposFechamento();
  }

void OnTick()
  {
   if(MostrarLinhasEquador)
     {
      MqlDateTime dtAgora; TimeToStruct(TimeCurrent(), dtAgora);
      if(dtAgora.year != AnoEquadorAtual || EquadorRange <= 0.0)
         DesenharEquadorCompleto();
      else
         AtualizarDistanciasEquador();
     }
   AtualizarMiniEquadorSeNecessario();
   datetime sessaoAgora = InicioSessao(TimeCurrent());
   if(sessaoAgora != SessaoAtual)
     {
      if(!ExistePosicaoDoRobo())
        { SessaoAtual = sessaoAgora; ResetarDia(); }
     }
   GerenciarLimitesDiarios();
   bool mudouManual = AtualizarCanalPorLinhasManuais();
   GerenciarBreakEven();
   VerificarFechamentoOperacao();
   VerificarPullbackAposVelaEsticada();
   if(mudouManual) ProcessarRompimentosAposAjusteManual();
   if(NovoCandle())
     {
      if(Estado == ESTADO_AGUARDANDO_CANAL)
        {
         if(MomentoFechamentoUltimaOperacao > 0 && PodeFazerMaisOperacoes())
            FormarNovoCanalAposFechamento();
         else if(MomentoFechamentoUltimaOperacao <= 0)
            FormarCanalAutomatico();
        }
      VerificarRompimentoCanalAbertura();
      VerificarRompimentoC1();
     }
   MostrarStatus();
  }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == BTN_START)
        {
         FormarCanalManual();
         ObjectSetInteger(0, BTN_START, OBJPROP_STATE, false);
         ChartRedraw();
        }
      if(sparam == BTN_PAINEL)
        {
         PainelVisivel = !PainelVisivel;
         AtualizarBotaoPainel();
         if(!PainelVisivel)
           {
            LimparLinhasPainelAntigas(MAX_LINHAS_PAINEL);
            ApagarObjeto(OBJ_PAINEL_FUNDO);
           }
         else MostrarStatus();
         ObjectSetInteger(0, BTN_PAINEL, OBJPROP_STATE, false);
         ChartRedraw();
        }
     }
   if(id == CHARTEVENT_OBJECT_DRAG)
     {
      if(sparam == OBJ_CA_TOPO || sparam == OBJ_CA_FUNDO)
        {
         bool mudou = AtualizarCanalPorLinhasManuais();
         if(mudou) ProcessarRompimentosAposAjusteManual();
         ChartRedraw();
        }
     }
  }
//+------------------------------------------------------------------+
