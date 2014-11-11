countMthHolidays <- function(dataset) {  
  # Função que verifica se um dado mês em um "dataset" contém feriados 
  # que não sejam no domingo.
  
  # Starting and ending years in 'dataset'
  startYear <- min(as.numeric(format(index(dataset), "%Y")))
  endYear <- max(as.numeric(format(index(dataset), "%Y")))
  yearRange <- startYear:endYear
  
  startMonth_1stYear <- as.numeric(format(index(dataset)[1], "%m"))
  endMonth_LastYear <- as.numeric(format(index(dataset)[length(dataset)], "%m"))
  
  # Declare vector for containing results
  #returnVec <- array(data=0, dim=(endYear - startYear + 1)*12)
  returnVec <- array(dim=0)
  
  for (i in 1:length(yearRange) ) {
    year <- yearRange[i]
    
    startMonth <- 1
    endMonth <- 12
    
    if(i==1)
      startMonth <- startMonth_1stYear
    
    if(i==length(yearRange))
      endMonth <- endMonth_LastYear
    
    for (month in startMonth:endMonth) {
      returnVec <- cbind(returnVec, 0)
      
      # Define feriados fixos:
      monthHolidays <- holidays[which(as.numeric(format(as.Date(holidays, format="%d/%m"), "%m")) == month)]
      # Coloca o ano da iteracao corrente na data destes feriados:
      if(length(monthHolidays) > 0) {
        monthHolidays <- paste(monthHolidays, year, sep="/")
      }
      # Feriados dinamicos:
      monthDynHolidays <- dynamicHolidays[which(format(as.Date(dynamicHolidays, format="%d/%m/%y"), "%m/%Y") == paste(formatC(month, width=2, flag = "0"), year, sep="/"))]
      # Formata:
      monthDynHolidays <- format(as.Date(monthDynHolidays, format="%d/%m/%y"), "%d/%m/%Y")
      
      # Define um conjunto que incorpora fixos e dinamicos
      totalHolidays <- union(monthHolidays, monthDynHolidays)
      
      # Para cada feriado do conjunto      
      for (holiday in totalHolidays) { 
        #print(month + (i-1)*12)
        feriado <- weekdays(as.Date(holiday, format="%d/%m/%Y"))
        if (feriado!="Saturday" && feriado!="Sunday") {
          #returnVec[month + (i-1)*12] <- returnVec[month + (i-1)*12] + 1
          returnVec[length(returnVec)] <- returnVec[length(returnVec)] + 1
        }
        #print(as.Date(holiday, format="%d/%m/%Y"))        
        #print(weekdays(as.Date(holiday, format="%d/%m/%Y")))
        #print(returnVec[month + (i-1)*12])
      }
    }
  }
  
  return(returnVec);
}

