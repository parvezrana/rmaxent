#' Show available versions of Maxent
#'
#' \code{maxent_versions} returns a vector of available version numbers.
#'
#' This obtains a vector of versions numbers for available versions of Maxent,
#' from https://github.com/mrmaxent/Maxent/tree/master/ArchivedReleases, as 
#' well as the latest version number from 
#' http://biodiversityinformatics.amnh.org/open_source/maxent.
#'
#' @param include_beta logical. Should beta versions be included?
#' @return Returns a \code{character} vector of version numbers.
#' @seealso \code{\link{get_maxent}}
#' @importFrom xml2 read_html
#' @importFrom rvest html_nodes html_text
#' @importFrom magrittr %>%
#' @export
#' @examples
#' \dontrun{
#' maxent_versions()
#' }
maxent_versions <- function(include_beta=FALSE) {
  u <- 'https://github.com/mrmaxent/Maxent/tree/master/ArchivedReleases'
  v <- xml2::read_html(u) %>%
    rvest::html_nodes(xpath='//tbody//tr//td[@class="content"]') %>%
    rvest::html_text()
  v <- gsub('^\\D+|\\n\\s*$', '', v)
  u2 <- 'http://biodiversityinformatics.amnh.org/open_source/maxent'
  v2 <- xml2::read_html(u2) %>%
    rvest::html_nodes(xpath='//*[@id="Form"]/h3[1]') %>% 
    rvest::html_text()
  v2 <- gsub('^\\s*Current\\s+version\\s*|\\s*$', '', v2)
  v <- c(v, v2)
  v <- sort(v[v!=''])
  if(!include_beta) grep('beta', v, invert=TRUE, value=TRUE) else v
}
