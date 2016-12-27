library(quantmod)
library(ggplot2)
library(plyr)
library(dplyr)

read_td_trans <- function(transaction_csv){
  trans = read.csv(transaction_csv, header=TRUE, stringsAsFactors=FALSE)
  trans[is.na(trans)] <- 0
  trans
}

remove_redundant_divid <- function(trans) {
  mody_plus <- trans[trans$AMOUNT>0,]
  mody_mius <- mody_plus
  mody_mius$AMOUNT <- mody_mius$AMOUNT * -1
  trans.redunt <- rbind(mody_plus, mody_mius)
  
  trans$deleteid <- paste0(trans$SYMBOL, trans$AMOUNT)
  trans.redunt$deleteid <- paste0(trans.redunt$SYMBOL, trans.redunt$AMOUNT)
  trans <- trans[!(trans$deleteid %in% trans.redunt$deleteid),]
  trans <- subset(trans, select = -c(deleteid) )
  trans
}

filter_td_trans <- function(trans, type="buy"){
  if( type == "wire_in"){
    trans.wire_in <- trans[grep("THIRD PARTY", trans$DESCRIPTION),]
    return ( trans.wire_in )
  } else if( type == "interst"){
    trans.interst <- trans[grep("FREE BALANCE INTEREST ADJUSTMENT", trans$DESCRIPTION),]
    return ( trans.interst )
  } else if( type == "buy" || type == "didv") {
    # The total stock cost and commission
    trans.buy <- trans[grep("Bought", trans$DESCRIPTION),]
    # The dividend amount
    # Note that this needs calibration, because some transaction records show -3.33 and +3.33.
    trans.didv <- trans.buy[trans.buy$QUANTITY<0.5,]
    trans.didv <- remove_redundant_divid(trans.didv)
    trans.buy <- trans.buy[trans.buy$QUANTITY>=0.5,]
    if( type == "buy") {
      return( trans.buy )
    }
    else if( type == "didv" ){
      return( trans.didv )
    }
  } else {
    trans.sel <- trans[grep("Sold", trans$DESCRIPTION),]
    return( trans.sel)
  }
}


get_pub_stock_data <- function(stock_list ){
  
  stock_data <- NULL
  for( name in stock_list) {
    stock_dt <- getSymbols(name, return.class="data.frame", auto.assign=FALSE)
    colnames(stock_dt) <- c("Open", "High", "Low", "Close", "Volumn", "Adjusted")
    #stock_dt$date <- strptime(row.names(stock_dt), "%Y-%m-%d") # convert date from string to datetime
    stock_dt$SYMBOL <- name
    row.names(stock_dt) <- NULL
    stock_data <- rbind(stock_data, stock_dt)
    rm(stock_dt)
    rm(name)
  }

  return(stock_data)
}

get_td_stock_position <- function(trans.buy, trans.didv, trans.sel, stock_data.now){
  by_stock_buy <- ddply(trans.buy, .(SYMBOL), summarize, buy_quant=sum(QUANTITY)) # add acc amount
  by_stock_didv <- ddply(trans.didv, .(SYMBOL), summarize, didv_quant=sum(QUANTITY)) # add acc amount
  by_stock_sel <- ddply(trans.sel, .(SYMBOL), summarize, sel_quant=sum(QUANTITY)) # add acc amount
  
  stock_position <- merge(by_stock_buy, by_stock_didv, by="SYMBOL", all.x=TRUE)
  stock_position <- merge(stock_position, by_stock_sel, by="SYMBOL", all.x=TRUE)
  stock_position[is.na(stock_position)] <- 0
  stock_position$now_quant <- stock_position$buy_quant + stock_position$didv_quant - stock_position$sel_quant
  stock_position <- merge(stock_position, stock_data.now, by="SYMBOL", all.x=TRUE)
  stock_position$value <- stock_position$now_quant * stock_position$Close
  stock_position
}


eva_history <- function(his, stock_data, sample_intval){
  stock_list <- unique(his$name)
  eva_his <- his
  eva_his$cost <- ifelse(eva_his$tran_type=="buy", eva_his$amount * eva_his$price, 0) # add cost for a single buy
  eva_his$date <- strptime(eva_his$date, "%Y-%m-%d") # convert date from string to datetime
  # Add sampling date if it does not exist
  sample_days <- seq(from=min(eva_his$date), to=as.POSIXct(Sys.Date()), by = paste(sample_intval, "day"))
  sample_days <- unique(c(sample_days, as.POSIXct(Sys.Date()))) # include the last day
  # Merge the sample days to transaction history
  null_tran <- NULL
  for( name in stock_list) {
    dt <- data.frame(name=name, date=sample_days)
    null_tran <- rbind(null_tran, dt)
  }
  eva_his <- merge(x = null_tran, y = eva_his, by = c("name", "date"), all.x=TRUE, all.y=TRUE, uncomparables=0)
  eva_his[is.na(eva_his$tran_type),]$tran_type <- 'empty'
  eva_his$shape <- ifelse(eva_his$tran_type=='buy', 16, ifelse(eva_his$tran_type=='divd', 17, 18)) # was 16, 17, 18?
  eva_his$point_size <- ifelse(eva_his$tran_type=='buy', 3, ifelse(eva_his$tran_type=='divd', 3, 2)) # was 16, 17, 18?
  eva_his[is.na(eva_his$amount),]$amount <- 0
  eva_his[is.na(eva_his$price),]$price <- 0
  eva_his[is.na(eva_his$cost),]$cost <- 0
  eva_his[is.na(eva_his$tran_fee),]$tran_fee <- 0
  eva_his <- eva_his[with(eva_his, order(date)), ]  # sort by date
  eva_his <- ddply(eva_his, .(name), transform, acc_amount=cumsum(amount)) # add acc amount
  eva_his <- ddply(eva_his, .(name), transform, acc_cost=cumsum(cost), acc_tran_fee=cumsum(tran_fee)) # add acc tran_fee
  eva_his <- merge(x=eva_his, y=stock_data, by=c("name", "date")) # left join the pub stock data
  eva_his$acc_mrket_value <- eva_his$acc_amount * eva_his$Close # calculate the accumulated market value
  eva_his <- ddply(eva_his, .(date), transform, mrket_value_portion = acc_mrket_value/sum(acc_mrket_value)) # calculate the market value portion
  eva_his$gain <- eva_his$acc_mrket_value - eva_his$acc_cost + eva_his$acc_tran_fee
  eva_his$gain_rate <- eva_his$gain/(eva_his$acc_cost - eva_his$acc_tran_fee)*100
  
  return(eva_his)
}

get_usdtwd_currency <- function() {
  getQuote("USDTWD=X")$Open
}