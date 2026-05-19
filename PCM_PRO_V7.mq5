//+------------------------------------------------------------------+
//|       PCM_PRO_V7.mq5                                             |
//|   CA + C1 operacional + pullback confirmado + take por rompimento |
//|   V7: correcao da primeira vela + hedge mode + reset duplo        |
//+------------------------------------------------------------------+
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
input double PercentualRangeTakeAposBreakEven = 10.0;

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
  { if(Timeframe==PERIOD_CURRENT) return (ENUM_TIMEFRAMES)_Period; return Timeframe; }

double NormalizarPreco(double preco) { return NormalizeDouble(preco, _Digits); }

datetime InicioSessao(datetime tempo)
  {
   MqlDateTime dt; TimeToStruct(tempo, dt);
   dt.hour=HoraInicioSessao; dt.min=MinutoInicioSessao; dt.sec=0;
   datetime inicio=StructToTime(dt);
   if(tempo<inicio) inicio-=86400;
   return inicio;
  }

bool DentroDoHorarioOperacao()
  {
   if(HoraLimiteOperacao==0 && MinutoLimiteOperacao==0) return true;
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   return (dt.hour*60+dt.min) < (HoraLimiteOperacao*60+MinutoLimiteOperacao);
  }

bool LimiteDiarioAtingido() { return StopDiarioAtingido||TakeDiarioAtingido; }

bool PodeFazerMaisOperacoes()
  {
   if(LimiteDiarioAtingido()) return false;
   if(MaximoOperacoesPorDia<=0) return true;
   return OperacoesHoje<MaximoOperacoesPorDia;
  }

datetime MomentoBaseRecriacaoCanais()
  { if(ConsiderarVelaFechamentoNaRecriacao) return iTime(_Symbol,TF(),0); return TimeCurrent(); }

bool NovoCandle()
  { datetime t=iTime(_Symbol,TF(),0); if(t!=UltimoBarProcessado){UltimoBarProcessado=t;return true;} return false; }

//+------------------------------------------------------------------+
//| V7 FIX 1: Helpers hedge-safe                                     |
//+------------------------------------------------------------------+
bool SelecionarPosicaoDoRobo(int indice, ulong &ticket)
  {
   ticket=0; int total=PositionsTotal(); int cnt=0;
   for(int i=0;i<total;i++){
      ulong tk=PositionGetTicket(i); if(tk==0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      if(cnt==indice){ticket=tk;return true;} cnt++;}
   return false;
  }

int ContarPosicoesDoRobo()
  {
   int total=PositionsTotal(); int cnt=0;
   for(int i=0;i<total;i++){
      ulong tk=PositionGetTicket(i); if(tk==0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      cnt++;}
   return cnt;
  }

bool ExistePosicaoDoRobo() { return ContarPosicoesDoRobo()>0; }

double LucroFlutuanteDoRobo()
  {
   double soma=0; int total=PositionsTotal();
   for(int i=0;i<total;i++){
      ulong tk=PositionGetTicket(i); if(tk==0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      soma+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);}
   return soma;
  }

void LogarFalhaTrade(string ctx)
  { Print("Trade FALHOU [",ctx,"] retcode=",trade.ResultRetcode()," ",trade.ResultRetcodeDescription()); }

void ApagarObjeto(string nome) { if(ObjectFind(0,nome)>=0) ObjectDelete(0,nome); }

void CriarLinhaHorizontal(string nome,double preco,color cor,ENUM_LINE_STYLE estilo,int largura,bool back,bool sel,string texto="")
  {
   ApagarObjeto(nome);
   ObjectCreate(0,nome,OBJ_HLINE,0,0,preco);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_STYLE,estilo);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,largura);
   ObjectSetInteger(0,nome,OBJPROP_BACK,back);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,sel);
   ObjectSetInteger(0,nome,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,false);
   if(texto!="") ObjectSetString(0,nome,OBJPROP_TEXT,texto);
  }

void CriarLinhaH(string nome,double preco,color cor,ENUM_LINE_STYLE estilo,int largura)
  { CriarLinhaHorizontal(nome,preco,cor,estilo,largura,false,true); }
void CriarLinhaEquador(string nome,double preco,color cor,ENUM_LINE_STYLE estilo,int largura)
  { CriarLinhaHorizontal(nome,preco,cor,estilo,largura,true,false); }
void CriarLinhaTopoFundo(string nome,double preco,color cor,ENUM_LINE_STYLE estilo,int largura,string texto)
  { CriarLinhaHorizontal(nome,preco,cor,estilo,largura,true,false,texto); }

void AtualizarLinhaH(string nome,double preco) { if(ObjectFind(0,nome)>=0) ObjectSetDouble(0,nome,OBJPROP_PRICE,preco); }
double LerPrecoLinha(string nome) { if(ObjectFind(0,nome)<0) return 0; return ObjectGetDouble(0,nome,OBJPROP_PRICE); }

void CriarTexto(string nome,string texto,datetime tempo,double preco,color cor)
  {
   if(!MostrarTextos) return;
   ApagarObjeto(nome);
   ObjectCreate(0,nome,OBJ_TEXT,0,tempo,preco);
   ObjectSetString(0,nome,OBJPROP_TEXT,texto);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,nome,OBJPROP_ANCHOR,ANCHOR_CENTER);
  }

void AtualizarTexto(string nome,datetime tempo,double preco) { if(ObjectFind(0,nome)>=0) ObjectMove(0,nome,0,tempo,preco); }

void CriarBotao()
  {
   ApagarObjeto(BTN_START);
   ObjectCreate(0,BTN_START,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,BTN_START,OBJPROP_XDISTANCE,BotaoDistanciaX);
   ObjectSetInteger(0,BTN_START,OBJPROP_YDISTANCE,BotaoDistanciaY);
   ObjectSetInteger(0,BTN_START,OBJPROP_XSIZE,80);
   ObjectSetInteger(0,BTN_START,OBJPROP_YSIZE,28);
   ObjectSetString(0,BTN_START,OBJPROP_TEXT,"INICIAR");
   ObjectSetInteger(0,BTN_START,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,BTN_START,OBJPROP_BGCOLOR,clrDodgerBlue);
   ObjectSetInteger(0,BTN_START,OBJPROP_BORDER_COLOR,clrWhite);
  }

void AtualizarBotaoPainel()
  {
   if(ObjectFind(0,BTN_PAINEL)<0) return;
   ObjectSetString(0,BTN_PAINEL,OBJPROP_TEXT,PainelVisivel?"OCULTAR PAINEL":"MOSTRAR PAINEL");
   ObjectSetInteger(0,BTN_PAINEL,OBJPROP_BGCOLOR,PainelVisivel?clrSlateGray:clrDarkGreen);
  }

void CriarBotaoPainel()
  {
   ApagarObjeto(BTN_PAINEL);
   ObjectCreate(0,BTN_PAINEL,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,BTN_PAINEL,OBJPROP_XDISTANCE,BotaoDistanciaX+90);
   ObjectSetInteger(0,BTN_PAINEL,OBJPROP_YDISTANCE,BotaoDistanciaY);
   ObjectSetInteger(0,BTN_PAINEL,OBJPROP_XSIZE,125);
   ObjectSetInteger(0,BTN_PAINEL,OBJPROP_YSIZE,28);
   ObjectSetInteger(0,BTN_PAINEL,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,BTN_PAINEL,OBJPROP_BORDER_COLOR,clrWhite);
   AtualizarBotaoPainel();
  }

void LimparLinhasPullbackVirtual()
  { ApagarObjeto(OBJ_PULLBACK);ApagarObjeto(OBJ_TAKE_VIRTUAL);ApagarObjeto(OBJ_STOP_VIRTUAL);ApagarObjeto(TXT_PULLBACK);ApagarObjeto(TXT_TAKE_VIRTUAL);ApagarObjeto(TXT_STOP_VIRTUAL); }

void LimparLinhas()
  { ApagarObjeto(OBJ_CA_TOPO);ApagarObjeto(OBJ_CA_FUNDO);ApagarObjeto(OBJ_CA_MEIO);ApagarObjeto(OBJ_C1_TOPO);ApagarObjeto(OBJ_C1_FUNDO);ApagarObjeto(OBJ_C1_MEIO);ApagarObjeto(OBJ_TAKE);ApagarObjeto(OBJ_TAKE_N2);ApagarObjeto(OBJ_TAKE_N3);ApagarObjeto(OBJ_STOP);ApagarObjeto(TXT_CA);ApagarObjeto(TXT_C1);LimparLinhasPullbackVirtual(); }

void LimparDadosPullbackVirtual()
  { AguardandoPullback=false;DirecaoPullback=0;LinhaPullback=0;TakeFicticio=0;StopFicticio=0;MovimentoEsticadoCancelado=false;PullbackTocado=false;MaximaVelaPullback=0;MinimaVelaPullback=0;CandleRompimentoEsticado=0;CandlePullbackTocado=0; }

void LimparDadosCanais()
  { CA_Topo=0;CA_Fundo=0;CA_Meio=0;CA_Tamanho=0;C1_Topo=0;C1_Fundo=0;C1_Meio=0;CandleCriacaoC1=0;LinhaTake=0;LinhaTakeN1=0;LinhaTakeN2=0;LinhaTakeN3=0;LinhaStop=0;RangeTakeAtual=0;PrecoEntradaAtual=0;DirecaoRompimento=0;CanalAtualEhGrande=false;CanalOperacionalTopo=0;CanalOperacionalFundo=0;CanalOperacionalTamanho=0;LinhaRompidaOperacao=0;DirecaoC1=0;LimparDadosPullbackVirtual(); }

void InicializarGerenciamentoDiario()
  { SaldoReferenciaDia=AccountInfoDouble(ACCOUNT_BALANCE);LimitePerdaDiariaValor=SaldoReferenciaDia*StopDiarioPercentual/100.0;MetaLucroDiariaValor=SaldoReferenciaDia*TakeDiarioPercentual/100.0;ResultadoFinanceiroDiaTotal=0;StopDiarioAtingido=false;TakeDiarioAtingido=false; }

void DispararAlerta(string msg)
  { if(!AtivarAlertas) return; Alert(_Symbol+" | "+msg); if(UsarSomNosAlertas&&ArquivoSomAlerta!="") PlaySound(ArquivoSomAlerta); }

void ResetarDia()
  { Estado=ESTADO_AGUARDANDO_CANAL;LimparDadosCanais();OperacoesHoje=0;TinhaPosicaoAberta=false;MomentoFechamentoUltimaOperacao=0;MomentoUltimoReset=0;CandleInicioNovaContagem=0;InicializarGerenciamentoDiario();LimparLinhas(); }

//+------------------------------------------------------------------+
//| LOTE                                                             |
//+------------------------------------------------------------------+
double AjustarVolume(double volume)
  {
   double volMin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double volMax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double volStep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(volume<volMin) volume=volMin;
   if(volume>volMax) volume=volMax;
   volume=MathFloor(volume/volStep)*volStep;
   return NormalizeDouble(volume,2);
  }

double CalcularLote(double precoEntrada,double precoStop)
  {
   if(!UsarLoteDinamico) return AjustarVolume(LoteFixo);
   double risco=AccountInfoDouble(ACCOUNT_EQUITY)*PercentualRiscoBanca/100.0;
   double tickSz=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickVal=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double volMin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double dist=MathAbs(precoEntrada-precoStop);
   if(tickSz<=0||tickVal<=0||dist<=0){Print("CalcularLote: dados invalidos");return 0;}
   double custo=dist/tickSz*tickVal; if(custo<=0) return 0;
   double lote=risco/custo;
   if(lote<volMin){Print("CalcularLote: risco nao paga volMin. Abortado.");return 0;}
   return AjustarVolume(lote);
  }

//+------------------------------------------------------------------+
//| CANAIS (V7 FIX: primeira vela nao e mais pulada)                 |
//+------------------------------------------------------------------+
double TamanhoVelaFiltroCanalPontos(int shift)
  {
   double o=iOpen(_Symbol,TF(),shift),c=iClose(_Symbol,TF(),shift);
   double h=iHigh(_Symbol,TF(),shift),l=iLow(_Symbol,TF(),shift);
   return (FiltroVelaGrandeCanalUsarCorpo?MathAbs(c-o):MathAbs(h-l))/_Point;
  }

bool VelaGrandeParaCanal(int shift)
  { if(!UsarFiltroVelaGrandeCanal||TamanhoMaximoVelaCanalPontos<=0) return false; return TamanhoVelaFiltroCanalPontos(shift)>TamanhoMaximoVelaCanalPontos; }

bool CalcularCanalPrimeirasVelas(datetime inicio,double &topo,double &fundo)
  {
   int total=iBars(_Symbol,TF()); if(total<=QuantidadeVelasCanal+2) return false;
   datetime candleAtual=iTime(_Symbol,TF(),0);
   int ps=PeriodSeconds(TF()); int cont=0; topo=-DBL_MAX; fundo=DBL_MAX;
   for(int shift=total-1;shift>=1;shift--)
     {
      datetime t=iTime(_Symbol,TF(),shift);
      if(t+ps<=inicio) continue;
      if(t>=candleAtual) continue;
      if(VelaGrandeParaCanal(shift)){cont=0;topo=-DBL_MAX;fundo=DBL_MAX;continue;}
      double o=iOpen(_Symbol,TF(),shift),c=iClose(_Symbol,TF(),shift);
      double h=iHigh(_Symbol,TF(),shift),l=iLow(_Symbol,TF(),shift);
      double mx,mn;
      if(UsarCorpoRealSemPavio){mx=MathMax(o,c);mn=MathMin(o,c);}else{mx=h;mn=l;}
      if(mx>topo) topo=mx; if(mn<fundo) fundo=mn;
      cont++; if(cont>=QuantidadeVelasCanal) break;
     }
   if(cont<QuantidadeVelasCanal||topo<=fundo) return false;
   return true;
  }

bool CalcularCanalUltimasVelas(double &topo,double &fundo)
  {
   int total=iBars(_Symbol,TF()); if(total<=QuantidadeVelasCanal+2) return false;
   topo=-DBL_MAX; fundo=DBL_MAX;
   for(int shift=QuantidadeVelasCanal;shift>=1;shift--)
     {
      double o=iOpen(_Symbol,TF(),shift),c=iClose(_Symbol,TF(),shift);
      double h=iHigh(_Symbol,TF(),shift),l=iLow(_Symbol,TF(),shift);
      double mx,mn;
      if(UsarCorpoRealSemPavio){mx=MathMax(o,c);mn=MathMin(o,c);}else{mx=h;mn=l;}
      if(mx>topo) topo=mx; if(mn<fundo) fundo=mn;
     }
   return topo>fundo;
  }

bool CalcularCanalAposHorario(datetime inicio,double &topo,double &fundo)
  {
   int total=iBars(_Symbol,TF()); if(total<=QuantidadeVelasCanal+2) return false;
   datetime candleAtual=iTime(_Symbol,TF(),0);
   int ps=PeriodSeconds(TF()); int cont=0; topo=-DBL_MAX; fundo=DBL_MAX;
   for(int shift=total-1;shift>=1;shift--)
     {
      datetime t=iTime(_Symbol,TF(),shift);
      if(ConsiderarVelaFechamentoNaRecriacao){if(t+ps<=inicio) continue;}
      else{if(t<=inicio) continue;}
      if(t>=candleAtual) continue;
      double o=iOpen(_Symbol,TF(),shift),c=iClose(_Symbol,TF(),shift);
      double h=iHigh(_Symbol,TF(),shift),l=iLow(_Symbol,TF(),shift);
      double mx,mn;
      if(UsarCorpoRealSemPavio){mx=MathMax(o,c);mn=MathMin(o,c);}else{mx=h;mn=l;}
      if(mx>topo) topo=mx; if(mn<fundo) fundo=mn;
      cont++; if(cont>=QuantidadeVelasCanal) break;
     }
   if(cont<QuantidadeVelasCanal||topo<=fundo) return false;
   return true;
  }

bool CalcularCanalExpansivoAposHorario(datetime inicio,bool incluirInicio,double &topo,double &fundo,int &velasUsadas)
  {
   int total=iBars(_Symbol,TF()); if(total<=QuantidadeVelasCanal+2) return false;
   datetime candleAtual=iTime(_Symbol,TF(),0);
   int ps=PeriodSeconds(TF());
   int limVelas=ExpandirCanalAteMinimoPontos?MathMax(QuantidadeVelasCanal,MaximoVelasParaExpandirCanal):QuantidadeVelasCanal;
   if(UsarCorpoRealSemPavio)
     {
      int cc=0; double tc=-DBL_MAX,fc=DBL_MAX;
      for(int s=total-1;s>=1;s--)
        {
         datetime t=iTime(_Symbol,TF(),s);
         if(incluirInicio){if(t+ps<=inicio) continue;}else{if(t<=inicio) continue;}
         if(t>=candleAtual) continue;
         if(VelaGrandeParaCanal(s)){cc=0;tc=-DBL_MAX;fc=DBL_MAX;continue;}
         double o=iOpen(_Symbol,TF(),s),c=iClose(_Symbol,TF(),s);
         double mx=MathMax(o,c),mn=MathMin(o,c);
         if(mx>tc)tc=mx; if(mn<fc)fc=mn; cc++;
         if(cc>=QuantidadeVelasCanal) break;
        }
      if(cc<QuantidadeVelasCanal||tc<=fc) return false;
      if((tc-fc)/_Point>=CanalMinimoPontos){topo=NormalizarPreco(tc);fundo=NormalizarPreco(fc);velasUsadas=cc;return true;}
      if(!ExpandirCanalAteMinimoPontos) return false;
      int cp=0; double tp=-DBL_MAX,fp=DBL_MAX;
      for(int s=total-1;s>=1;s--)
        {
         datetime t=iTime(_Symbol,TF(),s);
         if(incluirInicio){if(t+ps<=inicio) continue;}else{if(t<=inicio) continue;}
         if(t>=candleAtual) continue;
         if(VelaGrandeParaCanal(s)){cp=0;tp=-DBL_MAX;fp=DBL_MAX;continue;}
         double h=iHigh(_Symbol,TF(),s),l=iLow(_Symbol,TF(),s);
         if(h>tp)tp=h; if(l<fp)fp=l; cp++; velasUsadas=cp;
         if(cp>=QuantidadeVelasCanal&&(tp-fp)/_Point>=CanalMinimoPontos) break;
         if(cp>=limVelas) break;
        }
      if(cp<QuantidadeVelasCanal||tp<=fp) return false;
      if((tp-fp)/_Point<CanalMinimoPontos) return false;
      topo=NormalizarPreco(tp);fundo=NormalizarPreco(fp);velasUsadas=cp;return true;
     }
   int cont=0; topo=-DBL_MAX; fundo=DBL_MAX; velasUsadas=0;
   for(int s=total-1;s>=1;s--)
     {
      datetime t=iTime(_Symbol,TF(),s);
      if(incluirInicio){if(t+ps<=inicio) continue;}else{if(t<=inicio) continue;}
      if(t>=candleAtual) continue;
      if(VelaGrandeParaCanal(s)){cont=0;topo=-DBL_MAX;fundo=DBL_MAX;velasUsadas=0;continue;}
      double h=iHigh(_Symbol,TF(),s),l=iLow(_Symbol,TF(),s);
      if(h>topo)topo=h; if(l<fundo)fundo=l; cont++; velasUsadas=cont;
      if(cont>=QuantidadeVelasCanal){if(!ExpandirCanalAteMinimoPontos||(topo-fundo)/_Point>=CanalMinimoPontos) break;}
      if(cont>=limVelas) break;
     }
   if(cont<QuantidadeVelasCanal||topo<=fundo) return false;
   if((topo-fundo)/_Point<CanalMinimoPontos) return false;
   topo=NormalizarPreco(topo);fundo=NormalizarPreco(fundo);return true;
  }

double CalcularTamanhoCorpoPrimeirasVelasApos(datetime inicio)
  {
   int total=iBars(_Symbol,TF()); if(total<=QuantidadeVelasCanal+2) return 0;
   datetime candleAtual=iTime(_Symbol,TF(),0); int ps=PeriodSeconds(TF());
   int cont=0; double tc=-DBL_MAX,fc=DBL_MAX;
   for(int s=total-1;s>=1;s--)
     {
      datetime t=iTime(_Symbol,TF(),s);
      if(t+ps<=inicio) continue;
      if(t>=candleAtual) continue;
      if(VelaGrandeParaCanal(s)){cont=0;tc=-DBL_MAX;fc=DBL_MAX;continue;}
      double o=iOpen(_Symbol,TF(),s),c=iClose(_Symbol,TF(),s);
      double mx=MathMax(o,c),mn=MathMin(o,c);
      if(mx>tc)tc=mx; if(mn<fc)fc=mn; cont++;
      if(cont>=QuantidadeVelasCanal) break;
     }
   if(cont<QuantidadeVelasCanal||tc<=fc) return 0;
   return NormalizarPreco(tc)-NormalizarPreco(fc);
  }

bool CanalGrandePeloParametro()
  { double t=CA_Tamanho; if(MedirLimiteCanalGrandeSomenteCorpo&&CA_TamanhoCorpo>0) t=CA_TamanhoCorpo; return (t/_Point)>=LimiteCanalGrandePontos; }

void AtualizarCanalOperacional()
  {
   if(C1_Topo>0&&C1_Fundo>0){CanalOperacionalTopo=MathMax(CA_Topo,C1_Topo);CanalOperacionalFundo=MathMin(CA_Fundo,C1_Fundo);}
   else{CanalOperacionalTopo=CA_Topo;CanalOperacionalFundo=CA_Fundo;}
   CanalOperacionalTopo=NormalizarPreco(CanalOperacionalTopo);CanalOperacionalFundo=NormalizarPreco(CanalOperacionalFundo);
   CanalOperacionalTamanho=CanalOperacionalTopo-CanalOperacionalFundo;
  }

double FiltroRompimentoPontos(double rng,double pct) { if(rng<=0||pct<=0) return 0; return rng*pct/100.0; }
bool RompimentoValidoCompra(double f,double lr,double rng,double pct) { if(rng<=0) return false; return f>=(lr+FiltroRompimentoPontos(rng,pct)); }
bool RompimentoValidoVenda(double f,double lr,double rng,double pct) { if(rng<=0) return false; return f<=(lr-FiltroRompimentoPontos(rng,pct)); }

//+------------------------------------------------------------------+
//| EQUADOR + TOPOS FUNDOS                                           |
//+------------------------------------------------------------------+
void LimparLinhasEquador(){int t=ObjectsTotal(0,0,-1);for(int i=t-1;i>=0;i--){string n=ObjectName(0,i,0,-1);if(StringFind(n,PREFIXO_EQUADOR)==0) ObjectDelete(0,n);}}
void LimparLinhasMiniEquador(){int t=ObjectsTotal(0,0,-1);for(int i=t-1;i>=0;i--){string n=ObjectName(0,i,0,-1);if(StringFind(n,PREFIXO_MINI_EQUADOR)==0) ObjectDelete(0,n);}}
void LimparLinhasMiniEquadorTF(string tag){string pf=PREFIXO_MINI_EQUADOR+tag+"_";int t=ObjectsTotal(0,0,-1);for(int i=t-1;i>=0;i--){string n=ObjectName(0,i,0,-1);if(StringFind(n,pf)==0) ObjectDelete(0,n);}}
void EquadorRangeK(int &ik,int &fk){ik=-QuantidadeExpansoesEquador*4;fk=4+(QuantidadeExpansoesEquador*4);}
double EquadorPrecoNivel(int k){return NormalizarPreco(EquadorFundoBase+(EquadorRange*0.25*k));}

bool CalcularEquadorAnual()
  {
   if(!MostrarLinhasEquador) return false;
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt); int ano=dt.year;
   if(AnoEquadorAtual==ano&&EquadorRange>0) return true;
   double tp=-DBL_MAX,fd=DBL_MAX; int sem=0;
   int tw=iBars(_Symbol,PERIOD_W1); if(tw<=QuantidadeSemanasEquador+5) return false;
   for(int s=tw-1;s>=0;s--)
     {
      datetime ts=iTime(_Symbol,PERIOD_W1,s); if(ts<=0) continue;
      MqlDateTime ds; TimeToStruct(ts,ds); if(ds.year!=ano) continue;
      double o=iOpen(_Symbol,PERIOD_W1,s),c=iClose(_Symbol,PERIOD_W1,s),h=iHigh(_Symbol,PERIOD_W1,s),l=iLow(_Symbol,PERIOD_W1,s);
      double tv,fv;
      if(EquadorUsarCorpoSemPavio){tv=MathMax(o,c);fv=MathMin(o,c);}else{tv=h;fv=l;}
      if(tv>tp)tp=tv; if(fv<fd)fd=fv; sem++;
      if(sem>=QuantidadeSemanasEquador) break;
     }
   if(sem<QuantidadeSemanasEquador||tp<=fd) return false;
   EquadorTopoBase=NormalizarPreco(tp);EquadorFundoBase=NormalizarPreco(fd);
   EquadorRange=EquadorTopoBase-EquadorFundoBase;AnoEquadorAtual=ano;
   return EquadorRange>0;
  }

void AtualizarDistanciasEquador()
  {
   DistanciaEquadorN1Pct=0;DistanciaEquadorN2Pct=0;DistanciaEquadorN3Pct=0;
   PrecoEquadorN1MaisProximo=0;PrecoEquadorN2MaisProximo=0;PrecoEquadorN3MaisProximo=0;
   if(!MostrarLinhasEquador||EquadorRange<=0) return;
   double pa=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double m1=DBL_MAX,m2=DBL_MAX,m3=DBL_MAX;
   int ik,fk; EquadorRangeK(ik,fk);
   for(int k=ik;k<=fk;k++)
     {
      double pl=EquadorPrecoNivel(k); double d=MathAbs(pa-pl);
      if(k%4==0){if(d<m1){m1=d;PrecoEquadorN1MaisProximo=pl;}}
      else if(k%2==0){if(d<m2){m2=d;PrecoEquadorN2MaisProximo=pl;}}
      else{if(d<m3){m3=d;PrecoEquadorN3MaisProximo=pl;}}
     }
   if(m1<DBL_MAX) DistanciaEquadorN1Pct=m1/EquadorRange*100;
   if(m2<DBL_MAX) DistanciaEquadorN2Pct=m2/EquadorRange*100;
   if(m3<DBL_MAX) DistanciaEquadorN3Pct=m3/EquadorRange*100;
  }

void DesenharEquadorCompleto()
  {
   if(!MostrarLinhasEquador){LimparLinhasEquador();return;}
   if(!CalcularEquadorAnual()) return;
   LimparLinhasEquador();
   int ik,fk; EquadorRangeK(ik,fk);
   for(int k=ik;k<=fk;k++)
     {
      double p=EquadorPrecoNivel(k);
      bool n1=(k%4==0),n2=(!n1&&k%2==0),n3=(!n1&&!n2);
      if(n1&&!MostrarEquadorNivel1) continue;
      if(n2&&!MostrarEquadorNivel2) continue;
      if(n3&&!MostrarEquadorNivel3) continue;
      string nv="N3_";color cr=CorEquadorNivel3;ENUM_LINE_STYLE es=EstiloEquadorNivel3;int lg=LarguraEquadorNivel3;
      if(n1){nv="N1_";cr=CorEquadorNivel1;es=EstiloEquadorNivel1;lg=LarguraEquadorNivel1;}
      else if(n2){nv="N2_";cr=CorEquadorNivel2;es=EstiloEquadorNivel2;lg=LarguraEquadorNivel2;}
      CriarLinhaEquador(PREFIXO_EQUADOR+nv+IntegerToString(k),p,cr,es,lg);
     }
   AtualizarDistanciasEquador(); ChartRedraw();
  }

bool PrecoJaMarcado(double p,double &lst[],int tot,double tol){for(int i=0;i<tot;i++) if(MathAbs(p-lst[i])<=tol*_Point) return true; return false;}
bool EhTopoSwing(ENUM_TIMEFRAMES tf,int shift,int forca){double h=iHigh(_Symbol,tf,shift);if(h<=0)return false;for(int i=1;i<=forca;i++){if(iHigh(_Symbol,tf,shift-i)>=h)return false;if(iHigh(_Symbol,tf,shift+i)>h)return false;}return true;}
bool EhFundoSwing(ENUM_TIMEFRAMES tf,int shift,int forca){double l=iLow(_Symbol,tf,shift);if(l<=0)return false;for(int i=1;i<=forca;i++){if(iLow(_Symbol,tf,shift-i)<=l)return false;if(iLow(_Symbol,tf,shift+i)<l)return false;}return true;}

void DesenharTopoFundoTimeframe(ENUM_TIMEFRAMES tf,string tag,int barras,color cor)
  {
   if(!MostrarTopoFundoImportante) return;
   LimparLinhasMiniEquadorTF(tag);
   int tb=iBars(_Symbol,tf); if(tb<=ForcaSwingTopoFundo*2+10) return;
   int mx=MathMin(barras,tb-ForcaSwingTopoFundo-2); int lc=0;
   double pm[]; ArrayResize(pm,MaxLinhasTopoFundoPorTimeframe*2+10); int tm=0;
   for(int s=ForcaSwingTopoFundo+1;s<=mx;s++)
     {
      if(lc>=MaxLinhasTopoFundoPorTimeframe) break;
      if(EhTopoSwing(tf,s,ForcaSwingTopoFundo)){double p=NormalizarPreco(iHigh(_Symbol,tf,s));if(!PrecoJaMarcado(p,pm,tm,20)){pm[tm++]=p;CriarLinhaTopoFundo(PREFIXO_MINI_EQUADOR+tag+"_TOPO_"+IntegerToString(lc),p,cor,EstiloTopoFundo,LarguraTopoFundo,tag+" TOPO");lc++;}}
      if(lc>=MaxLinhasTopoFundoPorTimeframe) break;
      if(EhFundoSwing(tf,s,ForcaSwingTopoFundo)){double p=NormalizarPreco(iLow(_Symbol,tf,s));if(!PrecoJaMarcado(p,pm,tm,20)){pm[tm++]=p;CriarLinhaTopoFundo(PREFIXO_MINI_EQUADOR+tag+"_FUNDO_"+IntegerToString(lc),p,cor,EstiloTopoFundo,LarguraTopoFundo,tag+" FUNDO");lc++;}}
     }
  }

void DesenharMiniEquadorTopoFundo()
  {
   if(!MostrarTopoFundoImportante){LimparLinhasMiniEquador();return;}
   if(MostrarTopoFundoD1) DesenharTopoFundoTimeframe(PERIOD_D1,"D1",BarrasAnaliseTopoFundoD1,CorTopoFundoD1); else LimparLinhasMiniEquadorTF("D1");
   if(MostrarTopoFundoH4) DesenharTopoFundoTimeframe(PERIOD_H4,"H4",BarrasAnaliseTopoFundoH4,CorTopoFundoH4); else LimparLinhasMiniEquadorTF("H4");
   if(MostrarTopoFundoH1) DesenharTopoFundoTimeframe(PERIOD_H1,"H1",BarrasAnaliseTopoFundoH1,CorTopoFundoH1); else LimparLinhasMiniEquadorTF("H1");
   ChartRedraw();
  }

void AtualizarMiniEquadorSeNecessario()
  {
   if(!MostrarTopoFundoImportante) return; bool up=false;
   datetime d1=iTime(_Symbol,PERIOD_D1,0),h4=iTime(_Symbol,PERIOD_H4,0),h1=iTime(_Symbol,PERIOD_H1,0);
   if(d1!=UltimaAtualizacaoD1){UltimaAtualizacaoD1=d1;up=true;}
   if(h4!=UltimaAtualizacaoH4){UltimaAtualizacaoH4=h4;up=true;}
   if(h1!=UltimaAtualizacaoH1){UltimaAtualizacaoH1=h1;up=true;}
   if(up) DesenharMiniEquadorTopoFundo();
  }

//+------------------------------------------------------------------+
//| CANAIS VISUAIS + FORMACAO + ENTRADAS                             |
//+------------------------------------------------------------------+
void DesenharCanalAbertura()
  {
   CA_Meio=(CA_Topo+CA_Fundo)/2.0;
   CriarLinhaH(OBJ_CA_TOPO,CA_Topo,CorCanalAbertura,STYLE_SOLID,EspessuraLinhas);
   CriarLinhaH(OBJ_CA_FUNDO,CA_Fundo,CorCanalAbertura,STYLE_SOLID,EspessuraLinhas);
   CriarLinhaH(OBJ_CA_MEIO,CA_Meio,CorCanalAbertura,STYLE_DOT,1);
   CriarTexto(TXT_CA,"CA",iTime(_Symbol,TF(),0),CA_Meio,CorCanalAbertura);
   ChartRedraw();
  }

bool FormarCanalAutomatico()
  {
   if(!PodeFazerMaisOperacoes()) return false;
   double tp,fd; int vu=0; bool ok=false;
   if(ExpandirCanalAteMinimoPontos) ok=CalcularCanalExpansivoAposHorario(SessaoAtual,true,tp,fd,vu);
   else ok=CalcularCanalPrimeirasVelas(SessaoAtual,tp,fd);
   if(!ok||(tp-fd)/_Point<CanalMinimoPontos) return false;
   CA_Topo=NormalizarPreco(tp);CA_Fundo=NormalizarPreco(fd);CA_Tamanho=CA_Topo-CA_Fundo;CA_TamanhoCorpo=CA_Tamanho;
   if(MedirLimiteCanalGrandeSomenteCorpo){double cc=CalcularTamanhoCorpoPrimeirasVelasApos(SessaoAtual);if(cc>0)CA_TamanhoCorpo=cc;}
   CanalAtualEhGrande=CanalGrandePeloParametro();AtualizarCanalOperacional();DesenharCanalAbertura();
   if(AlertaAoCriarCanal) DispararAlerta("Canal criado: "+DoubleToString(CA_Tamanho/_Point,1)+" pts");
   Estado=ESTADO_AGUARDANDO_ROMPIMENTO_CA; return true;
  }

bool FormarNovoCanalAposFechamento()
  {
   if(MomentoFechamentoUltimaOperacao<=0) return false;
   double tp,fd; int vu=0;
   datetime base=MomentoFechamentoUltimaOperacao; bool incl=ConsiderarVelaFechamentoNaRecriacao;
   if(CandleInicioNovaContagem>0){base=CandleInicioNovaContagem;incl=false;}
   bool ok=false;
   if(ExpandirCanalAteMinimoPontos||CandleInicioNovaContagem>0) ok=CalcularCanalExpansivoAposHorario(base,incl,tp,fd,vu);
   else ok=CalcularCanalAposHorario(base,tp,fd);
   if(!ok||(tp-fd)/_Point<CanalMinimoPontos) return false;
   CA_Topo=NormalizarPreco(tp);CA_Fundo=NormalizarPreco(fd);CA_Tamanho=CA_Topo-CA_Fundo;CA_TamanhoCorpo=CA_Tamanho;
   if(MedirLimiteCanalGrandeSomenteCorpo){double cc=CalcularTamanhoCorpoPrimeirasVelasApos(base);if(cc>0)CA_TamanhoCorpo=cc;}
   CanalAtualEhGrande=CanalGrandePeloParametro();AtualizarCanalOperacional();DesenharCanalAbertura();
   if(AlertaAoCriarCanal) DispararAlerta("Canal criado: "+DoubleToString(CA_Tamanho/_Point,1)+" pts");
   Estado=ESTADO_AGUARDANDO_ROMPIMENTO_CA;CandleInicioNovaContagem=0; return true;
  }

bool FormarCanalManual()
  {
   if(ExistePosicaoDoRobo()){DispararAlerta("INICIAR bloqueado: posicao aberta.");return false;}
   if(AguardandoPullback){DispararAlerta("INICIAR bloqueado: pullback ativo.");return false;}
   if(!PodeFazerMaisOperacoes()) return false;
   double tp,fd; if(!CalcularCanalUltimasVelas(tp,fd)) return false;
   if((tp-fd)/_Point<CanalMinimoPontos) return false;
   CA_Topo=NormalizarPreco(tp);CA_Fundo=NormalizarPreco(fd);CA_Tamanho=CA_Topo-CA_Fundo;CA_TamanhoCorpo=CA_Tamanho;
   CanalAtualEhGrande=CanalGrandePeloParametro();DirecaoRompimento=0;MomentoFechamentoUltimaOperacao=0;
   LimparDadosPullbackVirtual();LimparLinhas();DesenharCanalAbertura();
   if(AlertaAoCriarCanal) DispararAlerta("Canal criado: "+DoubleToString(CA_Tamanho/_Point,1)+" pts");
   Estado=ESTADO_AGUARDANDO_ROMPIMENTO_CA; return true;
  }

void RecalcularC1PorCanalAtual()
  {
   if(Estado!=ESTADO_AGUARDANDO_ROMPIMENTO_C1) return;
   if(DirecaoRompimento==1){C1_Fundo=CA_Topo;C1_Topo=CA_Topo+CA_Tamanho;}
   else if(DirecaoRompimento==-1){C1_Topo=CA_Fundo;C1_Fundo=CA_Fundo-CA_Tamanho;}
   else return;
   C1_Topo=NormalizarPreco(C1_Topo);C1_Fundo=NormalizarPreco(C1_Fundo);C1_Meio=(C1_Topo+C1_Fundo)/2;
   AtualizarLinhaH(OBJ_C1_TOPO,C1_Topo);AtualizarLinhaH(OBJ_C1_FUNDO,C1_Fundo);AtualizarLinhaH(OBJ_C1_MEIO,C1_Meio);
   AtualizarTexto(TXT_C1,iTime(_Symbol,TF(),0),C1_Meio);
  }

bool AtualizarCanalPorLinhasManuais()
  {
   if(BloquearAtualizacaoManual||!PermitirAjusteManualLinhas||Estado<ESTADO_AGUARDANDO_ROMPIMENTO_CA) return false;
   double tl=LerPrecoLinha(OBJ_CA_TOPO),fl=LerPrecoLinha(OBJ_CA_FUNDO);
   if(tl<=0||fl<=0) return false;
   if(tl<fl){double tmp=tl;tl=fl;fl=tmp;}
   double nt=NormalizarPreco(tl),nf=NormalizarPreco(fl);
   if(MathAbs(nt-CA_Topo)<=_Point*0.5&&MathAbs(nf-CA_Fundo)<=_Point*0.5) return false;
   CA_Topo=nt;CA_Fundo=nf;CA_Tamanho=CA_Topo-CA_Fundo;CA_TamanhoCorpo=CA_Tamanho;
   CanalAtualEhGrande=CanalGrandePeloParametro();CA_Meio=(CA_Topo+CA_Fundo)/2;
   BloquearAtualizacaoManual=true;
   AtualizarLinhaH(OBJ_CA_TOPO,CA_Topo);AtualizarLinhaH(OBJ_CA_FUNDO,CA_Fundo);AtualizarLinhaH(OBJ_CA_MEIO,CA_Meio);
   BloquearAtualizacaoManual=false;
   AtualizarTexto(TXT_CA,iTime(_Symbol,TF(),0),CA_Meio);
   RecalcularC1PorCanalAtual();AtualizarCanalOperacional();ChartRedraw();return true;
  }

void CriarCanalC1(int dir)
  {
   DirecaoRompimento=dir;DirecaoC1=dir;
   if(dir==1){C1_Fundo=CA_Topo;C1_Topo=CA_Topo+CA_Tamanho;}
   else if(dir==-1){C1_Topo=CA_Fundo;C1_Fundo=CA_Fundo-CA_Tamanho;}
   C1_Topo=NormalizarPreco(C1_Topo);C1_Fundo=NormalizarPreco(C1_Fundo);C1_Meio=(C1_Topo+C1_Fundo)/2;
   CriarLinhaH(OBJ_C1_TOPO,C1_Topo,CorCanalC1,STYLE_SOLID,EspessuraLinhas);
   CriarLinhaH(OBJ_C1_FUNDO,C1_Fundo,CorCanalC1,STYLE_SOLID,EspessuraLinhas);
   CriarLinhaH(OBJ_C1_MEIO,C1_Meio,CorCanalC1,STYLE_DOT,1);
   CriarTexto(TXT_C1,"C1",iTime(_Symbol,TF(),0),C1_Meio,CorCanalC1);
   CandleCriacaoC1=iTime(_Symbol,TF(),1);AtualizarCanalOperacional();
   Estado=ESTADO_AGUARDANDO_ROMPIMENTO_C1;ChartRedraw();
  }

void CalcularNiveisTake(int dir,double base,double rng)
  {
   double d1=rng*(TakeN1Pct/100),d2=d1*2,d3=d1*3;
   if(dir==1){LinhaTakeN1=NormalizarPreco(base+d1);LinhaTakeN2=NormalizarPreco(base+d2);LinhaTakeN3=NormalizarPreco(base+d3);}
   else{LinhaTakeN1=NormalizarPreco(base-d1);LinhaTakeN2=NormalizarPreco(base-d2);LinhaTakeN3=NormalizarPreco(base-d3);}
   LinhaTake=LinhaTakeN1;RangeTakeAtual=d1;
  }

bool PodeComprar(){return DirecaoPermitida==DIRECAO_AMBOS||DirecaoPermitida==DIRECAO_COMPRA;}
bool PodeVender(){return DirecaoPermitida==DIRECAO_AMBOS||DirecaoPermitida==DIRECAO_VENDA;}

void DesenharTakeStop()
  {
   CriarLinhaH(OBJ_TAKE,LinhaTake,CorTake,STYLE_DASH,1);
   if((int)QuantidadeTakes>=2&&LinhaTakeN2>0) CriarLinhaH(OBJ_TAKE_N2,LinhaTakeN2,CorTake,STYLE_DOT,1); else ApagarObjeto(OBJ_TAKE_N2);
   if((int)QuantidadeTakes>=3&&LinhaTakeN3>0) CriarLinhaH(OBJ_TAKE_N3,LinhaTakeN3,CorTake,STYLE_DOT,1); else ApagarObjeto(OBJ_TAKE_N3);
   CriarLinhaH(OBJ_STOP,LinhaStop,CorStop,STYLE_DASH,1);ChartRedraw();
  }

void ExecutarCompra()
  {
   if(!PodeComprar()||ExistePosicaoDoRobo()||!DentroDoHorarioOperacao()||!PodeFazerMaisOperacoes()) return;
   AtualizarCanalOperacional(); if(CanalOperacionalTamanho<=0) return;
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   LinhaStop=NormalizarPreco(CanalOperacionalFundo-CanalOperacionalTamanho*PercentualStopForaCanal/100-BufferStopPontos*_Point);
   double baseTk=LinhaRompidaOperacao>0?LinhaRompidaOperacao:CanalOperacionalTopo;
   CalcularNiveisTake(1,baseTk,CanalOperacionalTamanho);
   double lote=CalcularLote(ask,LinhaStop);
   if(lote<=0){DispararAlerta("COMPRA abortada: lote 0");return;}
   DesenharTakeStop();LimparLinhasPullbackVirtual();LimparDadosPullbackVirtual();
   if(trade.Buy(lote,_Symbol,0,LinhaStop,LinhaTake,"FIMATHE COMPRA"))
     {OperacoesHoje++;TinhaPosicaoAberta=true;PrecoEntradaAtual=ask;Estado=ESTADO_OPERADO_DIA;if(AlertaAoEntrar)DispararAlerta("COMPRA em "+DoubleToString(ask,_Digits));}
   else LogarFalhaTrade("Buy");
  }

void ExecutarVenda()
  {
   if(!PodeVender()||ExistePosicaoDoRobo()||!DentroDoHorarioOperacao()||!PodeFazerMaisOperacoes()) return;
   AtualizarCanalOperacional(); if(CanalOperacionalTamanho<=0) return;
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   LinhaStop=NormalizarPreco(CanalOperacionalTopo+CanalOperacionalTamanho*PercentualStopForaCanal/100+BufferStopPontos*_Point);
   double baseTk=LinhaRompidaOperacao>0?LinhaRompidaOperacao:CanalOperacionalFundo;
   CalcularNiveisTake(-1,baseTk,CanalOperacionalTamanho);
   double lote=CalcularLote(bid,LinhaStop);
   if(lote<=0){DispararAlerta("VENDA abortada: lote 0");return;}
   DesenharTakeStop();LimparLinhasPullbackVirtual();LimparDadosPullbackVirtual();
   if(trade.Sell(lote,_Symbol,0,LinhaStop,LinhaTake,"FIMATHE VENDA"))
     {OperacoesHoje++;TinhaPosicaoAberta=true;PrecoEntradaAtual=bid;Estado=ESTADO_OPERADO_DIA;if(AlertaAoEntrar)DispararAlerta("VENDA em "+DoubleToString(bid,_Digits));}
   else LogarFalhaTrade("Sell");
  }

//+------------------------------------------------------------------+
//| PULLBACK + ROMPIMENTO + GERENCIAMENTO                            |
//+------------------------------------------------------------------+
bool VelaRompimentoEsticada(int shift,double rng)
  {
   if(!UsarFiltroVelaEsticada||rng<=0) return false;
   double o=iOpen(_Symbol,TF(),shift),c=iClose(_Symbol,TF(),shift),h=iHigh(_Symbol,TF(),shift),l=iLow(_Symbol,TF(),shift);
   double tam=UsarCorpoParaFiltroVela?MathAbs(c-o):MathAbs(h-l);
   return (tam/rng*100)>PercentualMaximoVelaRompimento;
  }

void DesenharPullbackVirtual()
  {
   if(!MostrarLinhasPullbackVirtual) return;
   CriarLinhaH(OBJ_PULLBACK,LinhaPullback,CorPullback,STYLE_DASHDOT,1);
   CriarLinhaH(OBJ_TAKE_VIRTUAL,TakeFicticio,CorTakeVirtual,STYLE_DOT,1);
   ApagarObjeto(OBJ_STOP_VIRTUAL);
   datetime tt=iTime(_Symbol,TF(),0);
   CriarTexto(TXT_PULLBACK,"PULLBACK",tt,LinhaPullback,CorPullback);
   CriarTexto(TXT_TAKE_VIRTUAL,"TAKE VIRTUAL",tt,TakeFicticio,CorTakeVirtual);
   ApagarObjeto(TXT_STOP_VIRTUAL);ChartRedraw();
  }

void IniciarEsperaPullback(int dir,double linhaRet,double takeFake)
  {
   if(!EntrarNoPullbackAposVelaEsticada){MomentoFechamentoUltimaOperacao=MomentoBaseRecriacaoCanais();LimparLinhas();LimparDadosCanais();Estado=ESTADO_AGUARDANDO_CANAL;return;}
   AguardandoPullback=true;PullbackTocado=false;DirecaoPullback=dir;
   LinhaPullback=NormalizarPreco(linhaRet);TakeFicticio=NormalizarPreco(takeFake);StopFicticio=0;
   MovimentoEsticadoCancelado=false;MaximaVelaPullback=0;MinimaVelaPullback=0;
   CandleRompimentoEsticado=iTime(_Symbol,TF(),1);CandlePullbackTocado=0;
   Estado=ESTADO_AGUARDANDO_PULLBACK;DesenharPullbackVirtual();
  }

void CancelarPullbackVoltarEsperaOperacao()
  {
   MovimentoEsticadoCancelado=true;AguardandoPullback=false;PullbackTocado=false;DirecaoPullback=0;
   LinhaPullback=0;TakeFicticio=0;StopFicticio=0;MaximaVelaPullback=0;MinimaVelaPullback=0;
   CandleRompimentoEsticado=0;CandlePullbackTocado=0;LimparLinhasPullbackVirtual();
   if(LimiteDiarioAtingido()) Estado=ESTADO_LIMITE_DIARIO_ATINGIDO;
   else if(PodeFazerMaisOperacoes()){AtualizarCanalOperacional();Estado=(C1_Topo>0&&C1_Fundo>0)?ESTADO_AGUARDANDO_ROMPIMENTO_C1:ESTADO_AGUARDANDO_ROMPIMENTO_CA;}
   else Estado=ESTADO_OPERADO_DIA;
  }

void ResetarPorTakeVirtual()
  {
   MovimentoEsticadoCancelado=true;
   datetime cf=iTime(_Symbol,TF(),1);
   if(CandleRompimentoEsticado>0&&cf==CandleRompimentoEsticado){MomentoFechamentoUltimaOperacao=CandleRompimentoEsticado;CandleInicioNovaContagem=CandleRompimentoEsticado;}
   else{MomentoFechamentoUltimaOperacao=MomentoBaseRecriacaoCanais();CandleInicioNovaContagem=0;}
   LimparLinhas();LimparDadosCanais();
   if(LimiteDiarioAtingido()) Estado=ESTADO_LIMITE_DIARIO_ATINGIDO;
   else if(PodeFazerMaisOperacoes()) Estado=ESTADO_AGUARDANDO_CANAL;
   else Estado=ESTADO_OPERADO_DIA;
  }

void VerificarPullbackAposVelaEsticada()
  {
   if(!AguardandoPullback||ExistePosicaoDoRobo()) return;
   double c1=iClose(_Symbol,TF(),1),h1=iHigh(_Symbol,TF(),1),l1=iLow(_Symbol,TF(),1);
   datetime cf=iTime(_Symbol,TF(),1);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID),ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(c1<=0) return;
   if(DirecaoPullback==1)
     {
      bool tv=TakeVirtualSomenteComFechamentoVela?(c1>=TakeFicticio):(bid>=TakeFicticio||h1>=TakeFicticio);
      if(tv){ResetarPorTakeVirtual();return;}
      if(!PullbackTocado){
         bool tocou=PullbackSomenteComFechamentoVela?(c1<=LinhaPullback-BufferPullbackPontos*_Point):(bid<=LinhaPullback-BufferPullbackPontos*_Point||l1<=LinhaPullback-BufferPullbackPontos*_Point);
         if(tocou){PullbackTocado=true;CandlePullbackTocado=cf;MaximaVelaPullback=h1;MinimaVelaPullback=l1;return;}}
      else{if(cf<=CandlePullbackTocado) return;
         if(c1>LinhaRompidaOperacao){AguardandoPullback=false;PullbackTocado=false;DirecaoPullback=0;LimparLinhasPullbackVirtual();ExecutarCompra();return;}
         CancelarPullbackVoltarEsperaOperacao();return;}
     }
   else if(DirecaoPullback==-1)
     {
      bool tv=TakeVirtualSomenteComFechamentoVela?(c1<=TakeFicticio):(ask<=TakeFicticio||l1<=TakeFicticio);
      if(tv){ResetarPorTakeVirtual();return;}
      if(!PullbackTocado){
         bool tocou=PullbackSomenteComFechamentoVela?(c1>=LinhaPullback+BufferPullbackPontos*_Point):(ask>=LinhaPullback+BufferPullbackPontos*_Point||h1>=LinhaPullback+BufferPullbackPontos*_Point);
         if(tocou){PullbackTocado=true;CandlePullbackTocado=cf;MaximaVelaPullback=h1;MinimaVelaPullback=l1;return;}}
      else{if(cf<=CandlePullbackTocado) return;
         if(c1<LinhaRompidaOperacao){AguardandoPullback=false;PullbackTocado=false;DirecaoPullback=0;LimparLinhasPullbackVirtual();ExecutarVenda();return;}
         CancelarPullbackVoltarEsperaOperacao();return;}
     }
  }

void ProcessarEntradaCompraComFiltro(double lr,double tf2,double rng){if(VelaRompimentoEsticada(1,rng)){IniciarEsperaPullback(1,lr,tf2);return;}ExecutarCompra();}
void ProcessarEntradaVendaComFiltro(double lr,double tf2,double rng){if(VelaRompimentoEsticada(1,rng)){IniciarEsperaPullback(-1,lr,tf2);return;}ExecutarVenda();}

void VerificarRompimentoCanalAbertura()
  {
   if(Estado!=ESTADO_AGUARDANDO_ROMPIMENTO_CA) return;
   double c1=iClose(_Symbol,TF(),1),h1=iHigh(_Symbol,TF(),1),l1=iLow(_Symbol,TF(),1);
   if(c1<=0) return;
   bool cg=CanalAtualEhGrande; AtualizarCanalOperacional();
   bool rc=false,rv=false;
   if(TravarDirecaoPorPavio){if(h1>CA_Topo)rc=true;if(l1<CA_Fundo)rv=true;}
   else{if(c1>CA_Topo)rc=true;if(c1<CA_Fundo)rv=true;}
   if(TravarDirecaoNoPrimeiroRompimento){if(DirecaoRompimento==1)rv=false;if(DirecaoRompimento==-1)rc=false;}
   if(rc){
      if(!PodeComprar()) return;
      if(!cg){if(!RompimentoValidoCompra(c1,CA_Topo,CA_Tamanho,PercentualRompimentoCriarC1))return;DirecaoRompimento=1;CriarCanalC1(1);return;}
      if(!RompimentoValidoCompra(c1,CA_Topo,CA_Tamanho,PercentualRompimentoEntrada))return;
      DirecaoRompimento=1;LinhaRompidaOperacao=CA_Topo;AtualizarCanalOperacional();
      ProcessarEntradaCompraComFiltro(LinhaRompidaOperacao,LinhaRompidaOperacao+(CanalOperacionalTamanho*(TakeN1Pct/100)),CanalOperacionalTamanho);return;}
   if(rv){
      if(!PodeVender()) return;
      if(!cg){if(!RompimentoValidoVenda(c1,CA_Fundo,CA_Tamanho,PercentualRompimentoCriarC1))return;DirecaoRompimento=-1;CriarCanalC1(-1);return;}
      if(!RompimentoValidoVenda(c1,CA_Fundo,CA_Tamanho,PercentualRompimentoEntrada))return;
      DirecaoRompimento=-1;LinhaRompidaOperacao=CA_Fundo;AtualizarCanalOperacional();
      ProcessarEntradaVendaComFiltro(LinhaRompidaOperacao,LinhaRompidaOperacao-(CanalOperacionalTamanho*(TakeN1Pct/100)),CanalOperacionalTamanho);return;}
  }

void VerificarRompimentoC1()
  {
   if(Estado!=ESTADO_AGUARDANDO_ROMPIMENTO_C1) return;
   double c1=iClose(_Symbol,TF(),1); datetime cf=iTime(_Symbol,TF(),1);
   if(c1<=0) return; AtualizarCanalOperacional(); if(CanalOperacionalTamanho<=0) return;
   if(cf==CandleCriacaoC1) return;
   if(c1>CanalOperacionalTopo){
      if(!PodeComprar()||!RompimentoValidoCompra(c1,CanalOperacionalTopo,CanalOperacionalTamanho,PercentualRompimentoEntrada)) return;
      LinhaRompidaOperacao=CanalOperacionalTopo;
      ProcessarEntradaCompraComFiltro(LinhaRompidaOperacao,LinhaRompidaOperacao+(CanalOperacionalTamanho*(TakeN1Pct/100)),CanalOperacionalTamanho);return;}
   if(c1<CanalOperacionalFundo){
      if(!PodeVender()||!RompimentoValidoVenda(c1,CanalOperacionalFundo,CanalOperacionalTamanho,PercentualRompimentoEntrada)) return;
      LinhaRompidaOperacao=CanalOperacionalFundo;
      ProcessarEntradaVendaComFiltro(LinhaRompidaOperacao,LinhaRompidaOperacao-(CanalOperacionalTamanho*(TakeN1Pct/100)),CanalOperacionalTamanho);return;}
  }

void ProcessarRompimentosAposAjusteManual()
  {if(!VerificarEntradaAposMoverLinhas||ExistePosicaoDoRobo()||AguardandoPullback) return;
   if(Estado==ESTADO_AGUARDANDO_ROMPIMENTO_CA) VerificarRompimentoCanalAbertura();
   else if(Estado==ESTADO_AGUARDANDO_ROMPIMENTO_C1) VerificarRompimentoC1();}

void AplicarResetPosOperacao()
  {
   datetime agora=TimeCurrent();
   if(MomentoUltimoReset>0&&(agora-MomentoUltimoReset)<=3) return;
   MomentoUltimoReset=agora;MomentoFechamentoUltimaOperacao=MomentoBaseRecriacaoCanais();
   LimparLinhas();LimparDadosCanais();
   if(LimiteDiarioAtingido()) Estado=ESTADO_LIMITE_DIARIO_ATINGIDO;
   else if(PodeFazerMaisOperacoes()) Estado=ESTADO_AGUARDANDO_CANAL;
   else Estado=ESTADO_OPERADO_DIA;
  }

void VerificarFechamentoOperacao(){bool tem=ExistePosicaoDoRobo();if(TinhaPosicaoAberta&&!tem) AplicarResetPosOperacao();TinhaPosicaoAberta=tem;}

void GerenciarBreakEven()
  {
   if(!UsarBreakEven||RangeTakeAtual<=0) return;
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID),ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double dA=RangeTakeAtual*PercentualRangeTakeParaBreakEven/100,dG=RangeTakeAtual*PercentualRangeTakeAposBreakEven/100;
   int tp=ContarPosicoesDoRobo();
   for(int idx=0;idx<tp;idx++){
      ulong tk=0; if(!SelecionarPosicaoDoRobo(idx,tk)||!PositionSelectByTicket(tk)) continue;
      long tipo=PositionGetInteger(POSITION_TYPE);double pe=PositionGetDouble(POSITION_PRICE_OPEN),sl=PositionGetDouble(POSITION_SL),tpv=PositionGetDouble(POSITION_TP);
      if(tipo==POSITION_TYPE_BUY){if((bid-pe)>=dA){double nsl=NormalizarPreco(pe+dG);if(sl==0||sl<nsl)trade.PositionModify(tk,nsl,tpv);}}
      else if(tipo==POSITION_TYPE_SELL){if((pe-ask)>=dA){double nsl=NormalizarPreco(pe-dG);if(sl==0||sl>nsl)trade.PositionModify(tk,nsl,tpv);}}}
  }

void AtualizarPlacarDiario()
  {
   PlacarGainDia=0;PlacarLossDia=0;TotalEntradasDia=0;SaldoFinanceiroDia=0;ResultadoPontosDia=0;
   if(!HistorySelect(SessaoAtual,TimeCurrent())) return;
   int td=HistoryDealsTotal();
   ulong epi[];double epr[];long ety[];int ec=0;
   ArrayResize(epi,td);ArrayResize(epr,td);ArrayResize(ety,td);
   for(int i=0;i<td;i++){ulong tk=HistoryDealGetTicket(i);if(tk==0)continue;if(HistoryDealGetString(tk,DEAL_SYMBOL)!=_Symbol)continue;if(HistoryDealGetInteger(tk,DEAL_MAGIC)!=MagicNumber)continue;if(HistoryDealGetInteger(tk,DEAL_ENTRY)!=DEAL_ENTRY_IN)continue;epi[ec]=(ulong)HistoryDealGetInteger(tk,DEAL_POSITION_ID);epr[ec]=HistoryDealGetDouble(tk,DEAL_PRICE);ety[ec]=HistoryDealGetInteger(tk,DEAL_TYPE);ec++;}
   for(int i=0;i<td;i++){ulong tk=HistoryDealGetTicket(i);if(tk==0)continue;if(HistoryDealGetString(tk,DEAL_SYMBOL)!=_Symbol)continue;if(HistoryDealGetInteger(tk,DEAL_MAGIC)!=MagicNumber)continue;if(HistoryDealGetInteger(tk,DEAL_ENTRY)!=DEAL_ENTRY_OUT)continue;long tp2=HistoryDealGetInteger(tk,DEAL_TYPE);if(tp2!=DEAL_TYPE_BUY&&tp2!=DEAL_TYPE_SELL)continue;
      double res=HistoryDealGetDouble(tk,DEAL_PROFIT)+HistoryDealGetDouble(tk,DEAL_COMMISSION)+HistoryDealGetDouble(tk,DEAL_SWAP);
      SaldoFinanceiroDia+=res;TotalEntradasDia++;if(res>0)PlacarGainDia++;else if(res<0)PlacarLossDia++;
      ulong pid=(ulong)HistoryDealGetInteger(tk,DEAL_POSITION_ID);double ps=HistoryDealGetDouble(tk,DEAL_PRICE);
      for(int j=0;j<ec;j++){if(epi[j]==pid){if(ety[j]==DEAL_TYPE_BUY)ResultadoPontosDia+=(ps-epr[j])/_Point;else ResultadoPontosDia+=(epr[j]-ps)/_Point;break;}}}
  }

void AtualizarResultadoFinanceiroDiaTotal(){AtualizarPlacarDiario();ResultadoFinanceiroDiaTotal=SaldoFinanceiroDia+LucroFlutuanteDoRobo();}

void GerenciarLimitesDiarios()
  {
   if(LimiteDiarioAtingido()) return;
   if(SaldoReferenciaDia<=0) InicializarGerenciamentoDiario();
   AtualizarResultadoFinanceiroDiaTotal();
   bool st=(UsarStopDiario&&StopDiarioPercentual>0&&ResultadoFinanceiroDiaTotal<=-LimitePerdaDiariaValor);
   bool tk=(UsarTakeDiario&&TakeDiarioPercentual>0&&ResultadoFinanceiroDiaTotal>=MetaLucroDiariaValor);
   if(!st&&!tk) return;
   if(st) StopDiarioAtingido=true; else TakeDiarioAtingido=true;
   if(AlertaLimiteDiario) DispararAlerta((StopDiarioAtingido?"STOP":"TAKE")+" DIARIO: "+DoubleToString(ResultadoFinanceiroDiaTotal,2));
   if(FecharPosicaoAoAtingirLimiteDiario){int n=ContarPosicoesDoRobo();for(int i=0;i<n;i++){ulong t2=0;if(SelecionarPosicaoDoRobo(i,t2))trade.PositionClose(t2);}}
   LimparLinhasPullbackVirtual();LimparDadosPullbackVirtual();Estado=ESTADO_LIMITE_DIARIO_ATINGIDO;
  }

//+------------------------------------------------------------------+
//| PAINEL + EVENTOS                                                 |
//+------------------------------------------------------------------+
void LimparLinhasPainelAntigas(int qtd){for(int i=0;i<qtd;i++){string n=OBJ_PAINEL_LINHA_PREFIXO+IntegerToString(i);if(ObjectFind(0,n)>=0)ObjectDelete(0,n);}}

void CriarOuAtualizarTextoPainel(int idx,string texto,int x,int y,color cor,int fs)
  {
   string n=OBJ_PAINEL_LINHA_PREFIXO+IntegerToString(idx);
   if(ObjectFind(0,n)<0){ObjectCreate(0,n,OBJ_LABEL,0,0,0);ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);ObjectSetString(0,n,OBJPROP_FONT,"Consolas");}
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);ObjectSetInteger(0,n,OBJPROP_COLOR,cor);ObjectSetInteger(0,n,OBJPROP_FONTSIZE,fs);ObjectSetString(0,n,OBJPROP_TEXT,texto);
  }

void DesenharFundoPainel(int alt)
  {
   if(ObjectFind(0,OBJ_PAINEL_FUNDO)<0){ObjectCreate(0,OBJ_PAINEL_FUNDO,OBJ_RECTANGLE_LABEL,0,0,0);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_BORDER_TYPE,BORDER_FLAT);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_COLOR,clrDimGray);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_BACK,false);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_HIDDEN,true);}
   ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_XDISTANCE,5);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_YDISTANCE,58);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_XSIZE,220);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_YSIZE,alt);ObjectSetInteger(0,OBJ_PAINEL_FUNDO,OBJPROP_BGCOLOR,clrBlack);
  }

void MostrarStatus()
  {
   if(!PainelVisivel){LimparLinhasPainelAntigas(MAX_LINHAS_PAINEL);ApagarObjeto(OBJ_PAINEL_FUNDO);Comment("");ChartRedraw();return;}
   AtualizarResultadoFinanceiroDiaTotal();
   string est="";
   if(Estado==ESTADO_AGUARDANDO_CANAL) est="Aguardando CA";
   else if(Estado==ESTADO_AGUARDANDO_ROMPIMENTO_CA) est="Aguardando romp CA";
   else if(Estado==ESTADO_AGUARDANDO_ROMPIMENTO_C1) est="Aguardando romp C1";
   else if(Estado==ESTADO_OPERADO_DIA) est="Limite ops atingido";
   else if(Estado==ESTADO_AGUARDANDO_PULLBACK) est="Aguardando pullback";
   else if(Estado==ESTADO_LIMITE_DIARIO_ATINGIDO) est=StopDiarioAtingido?"Stop diario":"Take diario";
   int x=15,y=66,p=18,f=10,ln=0;
   LimparLinhasPainelAntigas(MAX_LINHAS_PAINEL);
   CriarOuAtualizarTextoPainel(ln++,"FIMATHE PCM PRO V7",x,y,clrAqua,12);y+=p+2;
   CriarOuAtualizarTextoPainel(ln++,"Estado: "+est,x,y,clrWhite,f);y+=p;
   CriarOuAtualizarTextoPainel(ln++,"Ops: "+IntegerToString(OperacoesHoje)+(MaximoOperacoesPorDia>0?"/"+IntegerToString(MaximoOperacoesPorDia):""),x,y,clrWhite,f);y+=p;
   CriarOuAtualizarTextoPainel(ln++,"Resultado: "+DoubleToString(ResultadoFinanceiroDiaTotal,2),x,y,ResultadoFinanceiroDiaTotal>=0?clrLime:clrTomato,f);y+=p;
   CriarOuAtualizarTextoPainel(ln++,"Gains:"+IntegerToString(PlacarGainDia)+" Losses:"+IntegerToString(PlacarLossDia),x,y,clrGold,f);y+=p;
   CriarOuAtualizarTextoPainel(ln++,"Pontos: "+DoubleToString(ResultadoPontosDia,1),x,y,ResultadoPontosDia>=0?clrLime:clrTomato,f);y+=p;
   if(CA_Tamanho>0){CriarOuAtualizarTextoPainel(ln++,"CA: "+DoubleToString(CA_Tamanho/_Point,1)+" pts"+(CanalAtualEhGrande?" [GRANDE]":""),x,y,clrWhite,f);y+=p;}
   if(C1_Topo>0&&C1_Fundo>0){CriarOuAtualizarTextoPainel(ln++,"C1: "+DoubleToString((C1_Topo-C1_Fundo)/_Point,1)+" pts",x,y,clrOrange,f);y+=p;}
   if(AguardandoPullback){CriarOuAtualizarTextoPainel(ln++,"Pullback: "+(PullbackTocado?"RETOMADA":"TOQUE"),x,y,clrYellow,f);y+=p;}
   DesenharFundoPainel((y-58)+12);Comment("");ChartRedraw();
  }

//+------------------------------------------------------------------+
//| EVENTOS                                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   PREFIXO="FIMATHE_"+_Symbol+"_"+IntegerToString((int)MagicNumber)+"_";
   PREFIXO_EQUADOR=PREFIXO+"EQUADOR_";PREFIXO_MINI_EQUADOR=PREFIXO+"MINI_EQ_";
   BTN_START=PREFIXO+"BTN_START";BTN_PAINEL=PREFIXO+"BTN_PAINEL";
   OBJ_CA_TOPO=PREFIXO+"CA_TOPO";OBJ_CA_FUNDO=PREFIXO+"CA_FUNDO";OBJ_CA_MEIO=PREFIXO+"CA_MEIO";
   OBJ_C1_TOPO=PREFIXO+"C1_TOPO";OBJ_C1_FUNDO=PREFIXO+"C1_FUNDO";OBJ_C1_MEIO=PREFIXO+"C1_MEIO";
   OBJ_TAKE=PREFIXO+"TAKE";OBJ_TAKE_N2=PREFIXO+"TAKE_N2";OBJ_TAKE_N3=PREFIXO+"TAKE_N3";OBJ_STOP=PREFIXO+"STOP";
   OBJ_PULLBACK=PREFIXO+"PULLBACK";OBJ_TAKE_VIRTUAL=PREFIXO+"TAKE_VIRTUAL";OBJ_STOP_VIRTUAL=PREFIXO+"STOP_VIRTUAL";
   TXT_CA=PREFIXO+"TXT_CA";TXT_C1=PREFIXO+"TXT_C1";TXT_PULLBACK=PREFIXO+"TXT_PULLBACK";
   TXT_TAKE_VIRTUAL=PREFIXO+"TXT_TAKE_VIRTUAL";TXT_STOP_VIRTUAL=PREFIXO+"TXT_STOP_VIRTUAL";
   OBJ_PAINEL_FUNDO=PREFIXO+"PAINEL_FUNDO";OBJ_PAINEL_LINHA_PREFIXO=PREFIXO+"PAINEL_LINHA_";
   trade.SetExpertMagicNumber(MagicNumber);trade.SetDeviationInPoints(30);
   SessaoAtual=InicioSessao(TimeCurrent());
   CriarBotao();CriarBotaoPainel();ResetarDia();DesenharEquadorCompleto();DesenharMiniEquadorTopoFundo();
   TinhaPosicaoAberta=ExistePosicaoDoRobo();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason){Comment("");}

void PrepararRecriacaoAposFechamento(){AplicarResetPosOperacao();TinhaPosicaoAberta=ExistePosicaoDoRobo();}

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD) return;
   ulong deal=trans.deal; if(deal==0||!HistoryDealSelect(deal)) return;
   if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol) return;
   if(HistoryDealGetInteger(deal,DEAL_MAGIC)!=MagicNumber) return;
   if(HistoryDealGetInteger(deal,DEAL_ENTRY)!=DEAL_ENTRY_OUT) return;
   long tp2=HistoryDealGetInteger(deal,DEAL_TYPE);
   if(tp2!=DEAL_TYPE_BUY&&tp2!=DEAL_TYPE_SELL) return;
   if(AlertaAoTakeStop){long r=HistoryDealGetInteger(deal,DEAL_REASON);if(r==DEAL_REASON_TP)DispararAlerta("TAKE atingido");else if(r==DEAL_REASON_SL)DispararAlerta("STOP atingido");}
   PrepararRecriacaoAposFechamento();
  }

void OnTick()
  {
   if(MostrarLinhasEquador){MqlDateTime da;TimeToStruct(TimeCurrent(),da);if(da.year!=AnoEquadorAtual||EquadorRange<=0)DesenharEquadorCompleto();else AtualizarDistanciasEquador();}
   AtualizarMiniEquadorSeNecessario();
   datetime sa=InicioSessao(TimeCurrent());
   if(sa!=SessaoAtual){if(!ExistePosicaoDoRobo()){SessaoAtual=sa;ResetarDia();}}
   GerenciarLimitesDiarios();
   bool mm=AtualizarCanalPorLinhasManuais();
   GerenciarBreakEven();VerificarFechamentoOperacao();VerificarPullbackAposVelaEsticada();
   if(mm) ProcessarRompimentosAposAjusteManual();
   if(NovoCandle()){
      if(Estado==ESTADO_AGUARDANDO_CANAL){if(MomentoFechamentoUltimaOperacao>0&&PodeFazerMaisOperacoes())FormarNovoCanalAposFechamento();else if(MomentoFechamentoUltimaOperacao<=0)FormarCanalAutomatico();}
      VerificarRompimentoCanalAbertura();VerificarRompimentoC1();}
   MostrarStatus();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_OBJECT_CLICK){
      if(sparam==BTN_START){FormarCanalManual();ObjectSetInteger(0,BTN_START,OBJPROP_STATE,false);ChartRedraw();}
      if(sparam==BTN_PAINEL){PainelVisivel=!PainelVisivel;AtualizarBotaoPainel();if(!PainelVisivel){LimparLinhasPainelAntigas(MAX_LINHAS_PAINEL);ApagarObjeto(OBJ_PAINEL_FUNDO);}else MostrarStatus();ObjectSetInteger(0,BTN_PAINEL,OBJPROP_STATE,false);ChartRedraw();}}
   if(id==CHARTEVENT_OBJECT_DRAG){if(sparam==OBJ_CA_TOPO||sparam==OBJ_CA_FUNDO){if(AtualizarCanalPorLinhasManuais())ProcessarRompimentosAposAjusteManual();ChartRedraw();}}
  }
//+------------------------------------------------------------------+
