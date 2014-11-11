countWeekdaysPerMonth <- function(dataset) {
  countDays <- matrix(nrow=0, ncol=7)
  
  meses <- format(dataset, "%m")
  
  # dias da semana em intervalo numérico (0-domingo a 6-sabado)
  numeric_weekdays <- as.POSIXlt(dataset)$wday
  
  i_currentMonth <- 1
  i <- 1
  while(i<=length(dataset)) {
    
    currentMonth <- meses[i]
    countDays_currentMonth <- array(0, dim=7)
    ibegin_currentMonth <- i
    
    #print(c(currentMonth,meses[i]))
    
    # determinar qtos dias tem este mês
    while(currentMonth == meses[i] && i<=length(dataset)) {
      i <- i + 1
    }
    numDays_currentMonth <- i - ibegin_currentMonth
    #print(c("num days = ",numDays_currentMonth))
    
    # verificar qual eh o primeiro dia deste mês
    firstDay <- numeric_weekdays[ibegin_currentMonth]
    #print( c("first day = ", firstDay) )
    
    # contar quantos domingos,...sabados ha neste mês
    for(j in 1:7) {
      numeric_day <- j - 1
      
      if (numeric_day >= firstDay) {
        remainingDays <- numDays_currentMonth-1 - (numeric_day-firstDay)
      }
      else {
        remainingDays <- numDays_currentMonth-1 - (7-(firstDay-numeric_day))
      }
      
      
      countDays_currentMonth[j] <- 1 + floor(remainingDays/7)
    }
    
    
    countDays <- rbind(countDays, countDays_currentMonth)
    i_currentMonth <- i_currentMonth + 1
    
  }
  
  return (countDays)
}

