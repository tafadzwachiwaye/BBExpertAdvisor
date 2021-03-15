
#property copyright "Free to explore"
#property link      "https://github.com/tafadzwachiwaye/BBExpertAdvisor"
#property version   "1.00"
#property strict
int magicNumber = 888888;
int bbPeriod = 20;
int band1Std = 1;
int band2Std = 4;
input double riskPerTrade = 0.02;
int orderID;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

    double bbLower1 = iBands(Symbol(), 0, bbPeriod, band1Std, 0, PRICE_CLOSE  , MODE_LOWER, 0);
    double bbUpper1 = iBands(Symbol(), 0, bbPeriod, band1Std, 0, PRICE_CLOSE  , MODE_UPPER, 0);
    double bbMid = iBands(Symbol(), 0, bbPeriod, band1Std, 0, PRICE_CLOSE  , 0, 0);
    double bbLower2 = iBands(Symbol(), 0, bbPeriod, band2Std, 0, PRICE_CLOSE  , MODE_LOWER, 0);
    double bbUpper2 = iBands(Symbol(), 0, bbPeriod, band2Std, 0, PRICE_CLOSE  , MODE_UPPER, 0);
    Print("We are working!");
    
    if(!CheckIfOpenOrdersByMagicNB())//if there are no open orders, try open new position
    {
      if(Ask < bbLower1)
      {
         double stopLossPrice = NormalizeDouble(bbLower2, Digits);
         double takeProfitPrice = NormalizeDouble(bbMid, Digits); 
         double lotSize = OptimalLotSize(riskPerTrade, Ask, stopLossPrice);
         orderID = OrderSend(Symbol(), OP_BUYLIMIT, lotSize, Ask, 10, stopLossPrice, takeProfitPrice, NULL, magicNumber);
      }
      else if( Bid > bbUpper1)//shorting
      {
         double stopLossPrice = NormalizeDouble(bbUpper2, Digits);
         double takeProfitPrice = NormalizeDouble(bbMid, Digits);          
         double lotSize = OptimalLotSize(riskPerTrade, Bid, stopLossPrice);         
         orderID = OrderSend(Symbol(), OP_SELLLIMIT, lotSize, Bid, 10, stopLossPrice, takeProfitPrice, NULL, magicNumber);
      
      }
    }     
    else //update position if need be
      {
         if(OrderSelect(orderID, SELECT_BY_TICKET))
            {
               int orderType = OrderType();//0==long, 1==short 
               double currentMidLine = NormalizeDouble(bbMid, Digits);               
               double TP = OrderTakeProfit();
               double SL = OrderStopLoss();  
                            
               if(TP != currentMidLine)
               {
                  bool Ans = OrderModify(orderID,OrderOpenPrice(), SL, currentMidLine, 0);   
                  if (Ans == true)
                     {
                        Alert("Order modified: " + orderID);
                     }            
               }
            }
      }
  }
  
  double OptimalLotSize(double maxRiskPrc, int maxLossInPips)
  {      
      double accEquity = AccountEquity();  
      double lotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
      double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);      
      double maxLossDollar = accEquity * maxRiskPrc;      
      double maxLossInQuoteCurr = maxLossDollar / tickValue;      
      double optimalLotSize = NormalizeDouble(maxLossInQuoteCurr / (maxLossInPips * GetPipValue())/lotSize, 2);      
      return optimalLotSize;
  }
  
  double GetPipValue()
   {
       double dblCalcPipValue = dblTickValue();             
       if(MarketInfo( Symbol(), MODE_DIGITS ) == 5)
            dblCalcPipValue *= 10;
       return( dblCalcPipValue );
   }
//+------------------------------------------------------------------+
double dblTickValue()
{
      return( MarketInfo( Symbol(), MODE_TICKVALUE ) );
}

double OptimalLotSize(double maxRiskPrc, double entryPrice, double stopLoss)
{
      int maxLossInPips = MathAbs(entryPrice - stopLoss)/GetPipValue();
      double optLotSize = OptimalLotSize(maxRiskPrc, maxLossInPips);
      return optLotSize;
}

bool CheckIfOpenOrdersByMagicNB()
{
      int openOrders = OrdersTotal();
      for(int i= 0; i < openOrders; i++)
      {
      	if(OrderSelect(i, SELECT_BY_POS) ==true)
      	{
      		if(OrderMagicNumber() == magicNumber)
      		{
      			return true;
      		}
      	}   
      }
      return false;
}