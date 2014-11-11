countWorkDays <- function(dataset) {  
  # Função que conta quantos dias há no mês, descontando-se os sábados e domingos.
  
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
      dateStart = as.Date(paste(01, month, year, sep="/"), format="%d/%m/%Y")
      if (month < 12) {
        dateEnd = as.Date(paste(01, month+1, year, sep="/"), format="%d/%m/%Y")
      } else {
        dateEnd = as.Date(paste(01, 1, year + 1, sep="/"), format="%d/%m/%Y")
      }
      
      dayRange <- seq(from=dateStart, to=dateEnd, by="1 day")
      # Exclui a ultima entrada (primeiro dia do outro mês)
      dayRange <- dayRange[-length(dayRange)]
      
      
      #returnVec[month + (i-1)*12] <- sum(!weekdays(dayRange) %in% c("Saturday", "Sunday"))
      returnVec <- cbind(returnVec, sum(!weekdays(dayRange) %in% c("Saturday", "Sunday")))
    }
  }
  
  return(returnVec);
}

