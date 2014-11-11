# Cria vetor com 1's e 0's para identificar os meses (Jan a Dez)
# do conjunto de treinamento
getMonths <- function(input) {
  months <- array( 0, dim=c(length(input),11) )
  for (i in 1:length(input)) {
    if(input[i] == "01") {
      months[i,1] <- 1
    }
    else if(input[i] == "02") {
      months[i,2] <- 1
    }
    else if(input[i] == "03") {
      months[i,3] <- 1
    }
    else if(input[i] == "04") {
      months[i,4] <- 1
    }
    else if(input[i] == "05") {
      months[i,5] <- 1
    }
    else if(input[i] == "06") {
      months[i,6] <- 1
    }
    else if(input[i] == "07") {
      months[i,7] <- 1
    }
    else if(input[i] == "08") {
      months[i,8] <- 1
    }
    else if(input[i] == "09") {
      months[i,9] <- 1
    }
    else if(input[i] == "10") {
      months[i,10] <- 1
    }
    else if(input[i] == "11") {
      months[i,11] <- 1
    }
  }
  
  return (months)
}

