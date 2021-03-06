#' Parse Maxent lambdas information
#'
#' Parse Maxent .lambdas files to extract the types, weights, minima and maxima 
#' of features, as well as the fitted model's entropy and other values required
#' for predicting to new data.
#'
#' @param lambdas Either a \code{MaxEnt} fitted model object (fitted with the 
#'   \code{maxent} function in the \code{dismo} package), or a file path to a 
#'   Maxent .lambdas file.
#' @return A list (of class \code{lambdas}) with five elements: 
#'  \itemize{
#'   \item{\code{lambdas}}{: a \code{data.frame} describing the features used in
#'   a Maxent model, including their weights (lambdas), maxima, minima, and 
#'   type;}
#'   \item{\code{linearPredictorNormalizer}}{: a constant that ensures the
#'   linear predictor (the sum of clamped features multiplied by their 
#'   respective feature weights) is always negative (for numerical stability);} 
#'   \item{\code{densityNormalizer}}{: a scaling constant that ensures Maxent's 
#'   raw output sums to 1 over background points;}
#'   \item{\code{numBackgroundPoints}}{: the number of background points used in
#'   model training; and}
#'   \item{\code{entropy}}{: the entropy of the fitted model.}
#' }
#' @keywords maxent, predict, project
#' @references 
#' \itemize{
#'   \item{Wilson, P. W. (2009) \href{http://gsp.humboldt.edu/olm_2015/Courses/GSP_570/Learning Modules/10 BlueSpray_Maxent_Uncertinaty/MaxEnt lambda files.pdf}{\emph{Guidelines for computing MaxEnt model output values from a lambdas file}}.}
#'   \item{\emph{Maxent software for species habitat modeling, version 3.3.3k} help file (software freely available \href{https://www.cs.princeton.edu/~schapire/maxent/}{here}).}
#' }
#' @seealso \code{\link{read_mxe}} \code{\link{project}}
#' @importFrom methods is
#' @importFrom utils count.fields
#' @importFrom stats setNames
#' @export
#' @examples
#' # Below we use the dismo::maxent example to fit a Maxent model:
#' if (require(dismo) && require(rJava) && 
#'     file.exists(system.file('java/maxent.jar', package='dismo'))) {
#'   fnames <- list.files(system.file('ex', package="dismo"), '\\.grd$', 
#'                        full.names=TRUE )
#'   predictors <- stack(fnames)
#'   occurrence <- system.file('ex/bradypus.csv', package='dismo')
#'   occ <- read.table(occurrence, header=TRUE, sep=',')[,-1]
#'   me <- maxent(predictors, occ, path=file.path(tempdir(), 'example'), 
#'                factors='biome')
#' 
#'   # ... and then parse the lambdas information:
#'   lam <- parse_lambdas(me)
#'   lam
#'   str(lam, 1)
#'   
#'   parse_lambdas(file.path(tempdir(), 'example/species.lambdas'))
#'   
#' }
parse_lambdas <- function(lambdas) {
  if(methods::is(lambdas, 'MaxEnt')) {
    lambdas <- lambdas@lambdas
  } else {
    lambdas <- readLines(lambdas)
  }
  con <- textConnection(lambdas)
  n <- utils::count.fields(con, ',', quote='')
  close(con)
  meta <- stats::setNames(lapply(strsplit(lambdas[n==2], ', '), 
                                 function(x) as.numeric(x[2])),
                          sapply(strsplit(lambdas[n==2], ', '), '[[', 1))
  lambdas <- stats::setNames(data.frame(do.call(
    rbind, strsplit(lambdas[n==4], ', ')), stringsAsFactors=FALSE),
    c('feature', 'lambda', 'min', 'max'))
  lambdas[, -1] <- lapply(lambdas[, -1], as.numeric)
  lambdas$feature <- sub('=', '==', lambdas$feature)
  lambdas$feature <- sub('<', '<=', lambdas$feature)
  lambdas$type <- factor(sapply(lambdas$feature, function(x) {
    switch(gsub("\\w|\\.|-|\\(|\\)", "", x),
           "==" = 'categorical',
           "<=" = "threshold",
           "^" = "quadratic",
           "*" = "product", 
           "`" = "reverse_hinge",
           "'" = 'forward_hinge',
           'linear')
  }))
  vars <- gsub("\\^2|\\(.*<=|\\((.*)==.*|`|\\'|\\)", "\\1", lambdas$feature)
  lambdas$var <- sub('\\*', ',', vars)
  l <- c(list(lambdas=lambdas[, c(1, 6, 2:5)]), meta)
  class(l) <- 'lambdas'
  l
}
