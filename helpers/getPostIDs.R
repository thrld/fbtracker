
#' @description Posts have unique IDs inside facebook. 
#' This function gets IDs for a speciefied period of days, querying data retrospectively day-by-day.
#' @usage getPostIDs(page, token, since, until = Sys.Date())
#' @param page  A facebook-user ID or user name
#' @param token An OAuth 2.0 personal access token
#' @param since Date of first day from which on page's post IDs should be listed
#' requires unit-length input of class \code{Date} or \code{character}, with fromat '%Y/%m/%d'
#' @param until Date of last day to which page's post IDs should be listed
#' requires unit-length input of class \code{Date} or \code{character}, 
#' with fromat '%Y/%m/%d', defaults to \code{Sys.Date} 
#' @return Character vector with set post IDs posted on page from since- to until-date 
#' @import httr Rfacebook::getPage
getPostIDs <- function(page, token, since, until){
  
  required <- tryCatch(require(Rfacebook, quietly = TRUE), warning = function (w) w)
  if ("warning" %in% class(required)) stop(required$message)
  
  page_id <- page
  
  if(missing(since)) stop("Cannot get post IDs when `since` is not specified.")
  if(missing(until)) until <- Sys.Date(); # warning("No input to argument `until` specified; Using Sys.Date by default.")
  
  ifDateInput <- function(arg.input, use.format = "%Y/%m/%d") {
    input_is_Date <- any(class(arg.input) %in% c("POSIXt", "Date"))
    input_is_character <- ifelse(!input_is_Date, typeof(since) == "character", NA)
    
    if(input_is_Date) {
      return(arg.input)
    } else if (input_is_character) {
      if (!grepl("\\d{4}/\\d{2}/\\d{2}", arg.input)) stop("Method not applicable if input to `%s` violates 'YYYY/mm/dd' date format.")
      return(as.Date(since, format = use.format))
    } else {
      stop("Method not applicable if class of input to `%s` is neither 'Date' nor 'character'.")
    }
  }
  
  from_date <- tryCatch(ifDateInput(since), error = function(e) e)
  if ("error" %in% class(from_date)) stop(sprintf(from_date$message, "since"))
  
  last_day <- tryCatch(ifDateInput(until), error = function(e) e)
  if ("error" %in% class(last_day)) stop(sprintf(from_date$message, "until"))
  
  post_IDs <- vector(mode = "character", length = 0L)
  pos <- 0L
  
  while (from_date != last_day) {
    
    next_day <- from_date+1
    
    DayPosts <- tryCatch(Rfacebook::getPage(page = page_id,
                                            token = token,
                                            since = from_date,
                                            until = next_day,
                                            feed = FALSE),
                         warning = function(w) w,
                         error = function(e) e)
    
    if (!any(c("warning", "error") %in% class(DayPosts)) && class(DayPosts) == "data.frame") {
      if (nrow(DayPosts) != 0) {
        posts <- DayPosts[["id"]]
        post_IDs[seq_along(posts)+pos] <- posts
        pos <- pos + length(posts)
      }
    }
    
    from_date <- next_day
  }   
  
  return(post_IDs)
}
