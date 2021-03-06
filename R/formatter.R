#' Create a formatter function making HTML elements
#'
#' @param .tag HTML tag name
#' @param ... functions to create attributes of HTML element from data colums.
#' The unnamed element will serve as the function to produce the inner text of the
#' element. If no unnamed element is provided, \code{identity} function will be used
#' to preserve the string representation of the colum values.
#' @return a function that transforms a column of data (usually an atomic vector)
#' to formatted data represented in HTML and CSS.
#' @examples
#' top10red <- formatter("span",
#'   style = x ~ ifelse(order(x, decreasing = TRUE) <= 10, "color:red", NA))
#' yesno <- function(x) ifelse(x, "yes", "no")
#' formattable(mtcars, list(mpg = top10red, qsec = top10red, am = yesno))
#' @export
formatter <- function(.tag, ...) {
  args <- list(...)
  envir <- parent.frame()
  # if function to specify element inner text is missing,
  # then use identify to preserve the default text of
  # the column value
  if(length(args) == 0L || (!is.null(argnames <- names(args)) && all(nzchar(argnames)))) {
    args <- c(args, identity)
  }

  # create a closure for formattable to build output string
  function(x) {
    values <- lapply(args, function(arg) {
      value <- if(is.function(arg)) {
        arg(x)
      } else if(inherits(arg, "formula")) {
        eval_formula(arg, x, envir)
      } else arg
      if(is.null(value)) NA else value
    })
    tags <- .mapply(function(...) {
      attrs <- list(...)
      htmltools::tag(.tag, attrs[!is.na(attrs) & nzchar(attrs)])
    }, values, NULL)
    vapply(tags, as.character, character(1L))
  }
}
