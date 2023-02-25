formula_function <-
function(
    response_vec = NULL,
    variable_vec = NULL
  ) {
    as.formula(paste(
      response_vec,
      paste(variable_vec, collapse = "+"),
      sep = " ~ "
    ))
  }
