library(shiny)
library(scales)
source("finance_lib.R")

# Deployment command
# library(rsconnect)
# rsconnect::deployApp()

shinyServer(function(input, output, session) {

  read_td_trans_ <- reactive({
    # Read the TD Ameritrade transaction history file
    trans <- read_td_trans("transactions.csv")
    trans
  })

  output$trans <- DT::renderDataTable({
    trans <- read_td_trans_()
    DT::datatable(trans, options = list(pageLength = 20), rownames = FALSE)
  })
  
  output$trans_wire_in <- DT::renderDataTable({
    trans <- read_td_trans_()
    trans.wire_in <- filter_td_trans(trans, type="wire_in")
    DT::datatable(trans.wire_in, rownames = FALSE)
  })

  output$trans_interst <- DT::renderDataTable({
    trans <- read_td_trans_()
    trans.interst <- filter_td_trans(trans, type="interst")
    DT::datatable(trans.interst, rownames = FALSE)
  })

  output$trans_buy <- DT::renderDataTable({
    trans <- read_td_trans_()
    trans.buy <- filter_td_trans(trans, type="buy")
    DT::datatable(trans.buy, rownames = FALSE)
  })
  
  output$trans_buy_bydate <- DT::renderDataTable({
    trans <- read_td_trans_()
    trans.buy <- filter_td_trans(trans, type="buy")
    DT::datatable(ddply(trans.buy, .(DATE), summarize, AMOUNT=sum(AMOUNT)), rownames = FALSE)
  })

  output$trans_didv <- DT::renderDataTable({
    trans <- read_td_trans_()
    trans.didv <- filter_td_trans(trans, type="didv")
    DT::datatable(trans.didv, rownames = FALSE)
  })
  
  output$trans_sel <- DT::renderDataTable({
    trans <- read_td_trans_()
    trans.sel <- filter_td_trans(trans, type="sel")
    DT::datatable(trans.sel, rownames = FALSE)
  })

  get_pub_stock_data_ <- reactive({
    trans <- read_td_trans_()
    symbols <- unique(trans$SYMBOL)
    symbols <- symbols[symbols != ""]
    stock_data <- get_pub_stock_data(symbols)
    stock_data
  })

  stock_data <- reactiveFileReader(1000, session, 'stock_data.csv', read.csv)
  
  get_td_stock_position_ <- reactive({
    #stock_data <- get_pub_stock_data_()
    stock_data <- stock_data()
    stock_data.now <- ddply(stock_data, .(SYMBOL), function(x) x[nrow(x), ])
    trans <- read_td_trans_()
    trans.buy <- filter_td_trans(trans, type="buy")
    trans.didv <- filter_td_trans(trans, type="didv")
    trans.sel <- filter_td_trans(trans, type="sel")
    stock_position <- get_td_stock_position(trans.buy, trans.didv, trans.sel, stock_data.now)
  })
  
  output$stock_position <- DT::renderDataTable({
    stock_position <- get_td_stock_position_()
    DT::datatable(stock_position, rownames = FALSE)
  })
  
  output$balance <- DT::renderDataTable({
    trans <- read_td_trans_()
    trans.wire_in <- filter_td_trans(trans, type="wire_in")
    trans.buy <- filter_td_trans(trans, type="buy")
    trans.didv <- filter_td_trans(trans, type="didv")
    trans.sel <- filter_td_trans(trans, type="sel")
    stock_position <- get_td_stock_position_()

    wire_in <- sum(trans.wire_in$AMOUNT)
    stock_cost <- sum(trans.buy$QUANTITY * trans.buy$PRICE)
    buy_cmisn <- sum(trans.buy$COMMISSION)
    didv_gain <- sum(trans.didv$QUANTITY * trans.didv$PRICE)
    stock_sel <- sum(trans.sel$QUANTITY * trans.sel$PRICE)
    sel_cmisn <- sum(trans.sel$COMMISSION)
    stock_cur_value <- sum(stock_position$value)

    balance <- wire_in - stock_cost - buy_cmisn + stock_sel - sel_cmisn
    trade_profit <- stock_cur_value + stock_sel - (stock_cost + buy_cmisn + sel_cmisn)
    trade_profit_rate <- round((stock_cur_value + stock_sel - (stock_cost + buy_cmisn + sel_cmisn))/(stock_cost + buy_cmisn + sel_cmisn), 4)
    account_value <- balance + stock_cur_value
    account_profit <- account_value - wire_in
    account_profit_rate <- round(account_profit / wire_in, digits=4)
    show_tb <- data.frame(part=c('匯入資金', '買股票花費(不含手續費)', '買入交易手續費',
                                 '賣出股票所得', '賣出交易手續費',
                                 '目前持有股票價值', '股息再投入股票',
                                 '(統計) 目前帳戶資金',
                                 '(統計) 目前股票價值',
                                 '(統計) 買賣獲利',
                                 '(統計) 買賣獲利率',
                                 '(統計) 目前帳戶價值',
                                 '(統計) 目前帳戶累計獲利',
                                 '(統計) 目前帳戶累計獲利率'),
                          value_usd=c(wire_in, stock_cost, buy_cmisn,
                                      stock_sel, sel_cmisn,
                                      stock_cur_value, didv_gain,
                                      balance,
                                      stock_cur_value,
                                      trade_profit,
                                      trade_profit_rate,
                                      account_value,
                                      account_profit,
                                      account_profit_rate))
    show_tb$value_twd <- round(show_tb$value_usd * get_usdtwd_currency(), 0)
    DT::datatable(show_tb, options = list(pageLength = 20), rownames = FALSE)
  })
  
})
