library(shiny)

shinyUI(navbarPage("Investment Agent",
                   tabPanel("TD原始交易紀錄",
                            p("以下是由TD Ameritrade下載的transaction.csv的原始交易紀錄．"),
                            div(DT::dataTableOutput("trans"), style = "font-size: 75%; width: 75%")
                   ),
                   tabPanel("TD分類交易紀錄",
                            p("TD Ameritrade原始交易紀錄可分為以下這些類別：(截至目前根據我自己的觀察)"),
                            tags$ul(
                              tags$li("現金匯入"), 
                              tags$ul(
                                tags$li("從國內或是美國匯進的現金")
                              ),
                              tags$li("現金利息"),
                              tags$ul(
                                tags$li("由帳戶內的現金產生的利息")
                              ),
                              tags$li("買股票"),
                              tags$ul(
                                tags$li("由帳戶內的現金買股票的交易，包含交易手續費紀錄也含在內")
                              ),
                              tags$li("賣股票"),
                              tags$ul(
                                tags$li("將帳戶內股票賣掉的交易，包含交易手續費紀錄也含在內")
                              ),
                              tags$li("股息再買入"),
                              tags$ul(
                                tags$li("如果有加入股息再投入計畫的話，會有這部分的交易紀錄"),
                                tags$li("股息產生的現金，再買入該股票的紀錄")
                              )
                            ),
                            h3("現金匯入"),
                            div(DT::dataTableOutput("trans_wire_in"), style = "font-size: 75%; width: 75%"),
                            h3("現金利息"),
                            div(DT::dataTableOutput("trans_interst"), style = "font-size: 75%; width: 75%"),
                            h3("買股票"),
                            navbarPage("",
                                       tabPanel("原始紀錄",
                                                div(DT::dataTableOutput("trans_buy"), style = "font-size: 75%; width: 75%")
                                       ),
                                       tabPanel("只看日期",
                                                div(DT::dataTableOutput("trans_buy_bydate"), style = "font-size: 75%; width: 75%")
                                       )
                            ),
                            h3("股息再買入"),
                            div(DT::dataTableOutput("trans_didv"), style = "font-size: 75%; width: 75%"),
                            h3("賣股票"),
                            div(DT::dataTableOutput("trans_sel"), style = "font-size: 75%; width: 75%")
                   ),
                   tabPanel("總覽",
                            p("要計算各樣統計資訊，需要了解資金主要由這幾部分所構成："),
                            tags$ul(
                              tags$li("現金"), 
                              tags$ul(
                                tags$li("匯入資金")
                              ),
                              tags$li("買賣股票"),
                              tags$ul(
                                tags$li("買股票成本"),
                                tags$li("買入交易手續費"),
                                tags$li("賣出股票所得"),
                                tags$li("賣出交易手續費")
                              ),
                              tags$li("目前持有股票"),
                              tags$ul(
                                tags$li("目前持有股票價值"),
                                tags$ul(
                                  tags$li("股息再投入股票")
                                )
                              )
                            ),
                            p("目前帳戶資金計算：匯入資金 - 股票成本 - 買入交易手續費 + 賣出股票所得 - 賣出交易手續費"),
                            p("目前帳戶價值計算：匯入資金 - 股票成本 - 買入交易手續費 + 賣出股票所得 - 賣出交易手續費 + 目前持有股票價值"),
                            p("買賣獲利計算：目前持有股票價值 + 賣出股票所得 - (股票成本 + 買入交易手續費 + 賣出交易手續費)"),
                            p("買賣獲利率計算：(目前持有股票價值 + 賣出股票所得 - (股票成本 + 買入交易手續費 + 賣出交易手續費)) / (股票成本 + 買入交易手續費 + 賣出交易手續費)"),
                            p("帳戶獲利計算：目前帳戶價值 - 匯入資金"),
                            p("帳戶獲利率計算：(目前帳戶價值 - 匯入資金)/匯入資金"),
                            h3("資金統計"),
                            div(DT::dataTableOutput("balance"), style = "font-size: 75%; width: 75%"),
                            h3("股票總覽"),
                            div(DT::dataTableOutput("stock_position"), style = "font-size: 75%; width: 75%")
                   )
))

