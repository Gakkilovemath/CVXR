#'
#' The Constant class.
#'
#' This class represents a constant.
#'
#' @slot value A numeric element, vector, matrix, or data.frame. Vectors are automatically cast into a matrix column.
#' @slot is_1D_array (Internal) A logical value indicating whether the value is a vector or 1-D matrix.
#' @slot sparse (Internal) A logical value indicating whether the value is a sparse matrix.
#' @slot size (Internal) A vector of containing the number of rows and columns.
#' @slot is_pos (Internal) A logical value indicating whether all elements are non-negative.
#' @slot is_neg (Internal) A logical value indicating whether all elements are non-positive.
#' @name Constant-class
#' @aliases Constant
#' @rdname Constant-class
.Constant <- setClass("Constant", representation(value = "ConstVal", is_1D_array = "logical", sparse = "logical", size = "numeric", is_pos = "logical", is_neg = "logical"),
                                 prototype(value = NA_real_, is_1D_array = FALSE, sparse = NA, size = NA_real_, is_pos = NA, is_neg = NA),
                      validity = function(object) {
                        if((!is(object@value, "ConstSparseVal") && !is.data.frame(object@value) && !is.numeric(object@value)) ||
                           ((is(object@value, "ConstSparseVal") || is.data.frame(object@value)) && !all(sapply(object@value, is.numeric))))
                          stop("[Constant: validation] value must be a data.frame, matrix (CsparseMatrix, TsparseMatrix, or R default), vector, or atomic element containing only numeric entries")
                        return(TRUE)
                      }, contains = "Leaf")

#' @param value A numeric element, vector, matrix, or data.frame. Vectors are automatically cast into a matrix column.
#' @rdname Constant-class
#' @examples
#' x <- Constant(5)
#' y <- Constant(diag(3))
#' get_data(y)
#' value(y)
#' is_positive(y)
#' size(y)
#' as.Constant(y)
#' @export
Constant <- function(value) { .Constant(value = value) }

setMethod("initialize", "Constant", function(.Object, ..., value = NA_real_, is_1D_array = FALSE, .sparse = NA, .size = NA_real_, .is_pos = NA, .is_neg = NA) {
  .Object@is_1D_array <- is_1D_array
  .Object@value <- value
  if(is(value, "ConstSparseVal")) {
    .Object@value <- Matrix(value, sparse = TRUE)
    .Object@sparse <- TRUE
  } else {
    if(is.vector(value) && length(value) > 1)
      .Object@is_1D_array <- TRUE
    .Object@value <- as.matrix(value)
    .Object@sparse <- FALSE
  }
  .Object@size <- intf_size(.Object@value)
  sign <- intf_sign(.Object@value)
  .Object@is_pos <- sign[1]
  .Object@is_neg <- sign[2]
  callNextMethod(.Object, ...)
})

setMethod("show", "Constant", function(object) {
  cat("Constant(", curvature(object), ", ", sign(object), ", (", paste(size(object), collapse = ","), "))", sep = "")
})

#' @param x,object A \linkS4class{Constant} object.
#' @rdname Constant-class
setMethod("as.character", "Constant", function(x) {
  paste("Constant(", curvature(x), ", ", sign(x), ", (", paste(size(x), collapse = ","), "))", sep = "")
})

#' @describeIn Constant Returns itself as a constant.
setMethod("constants", "Constant", function(object) { list(object) })

#' @describeIn Constant A list with the value of the constant.
setMethod("get_data", "Constant", function(object) { list(value(object)) })

#' @describeIn Constant The value of the constant.
setMethod("value", "Constant", function(object) { object@value })

#' @describeIn Constant An empty list since the gradient of a constant is zero.
setMethod("grad", "Constant", function(object) { list() })

#' @describeIn Constant The \code{c(row, col)} dimensions of the constant.
setMethod("size", "Constant", function(object) { object@size })

#' @describeIn Constant A logical value indicating whether all elemenets of the constant are non-negative.
setMethod("is_positive", "Constant", function(object) { object@is_pos })

#' @describeIn Constant A logical value indicating whether all elemenets of the constant are non-positive.
setMethod("is_negative", "Constant", function(object) { object@is_neg })

#' @describeIn Constant The canonical form of the constant.
setMethod("canonicalize", "Constant", function(object) {
  obj <- create_const(value(object), size(object), object@sparse)
  list(obj, list())
})

#'
#' Cast to a Constant
#'
#' Coerce an R object or expression into the \linkS4class{Constant} class.
#'
#' @param expr An \linkS4class{Expression}, numeric element, vector, matrix, or data.frame.
#' @return A \linkS4class{Constant} representing the input as a constant.
#' @docType methods
#' @rdname Constant-class
#' @export
as.Constant <- function(expr) {
  if(is(expr, "Expression"))
    expr
  else
    Constant(value = expr)
}

#'
#' The Parameter class.
#'
#' This class represents a parameter, either scalar or a matrix.
#'
#' @slot id (Internal) A unique integer identification number used internally.
#' @slot rows The number of rows in the parameter.
#' @slot cols The number of columns in the parameter.
#' @slot name (Optional) A character string representing the name of the parameter.
#' @slot sign_str A character string indicating the sign of the parameter. Must be "ZERO", "POSITIVE", "NEGATIVE", or "UNKNOWN".
#' @slot value (Optional) A numeric element, vector, matrix, or data.frame. Defaults to \code{NA} and may be changed with \code{value<-} later.
#' @name Parameter-class
#' @aliases Parameter
#' @rdname Parameter-class
.Parameter <- setClass("Parameter", representation(id = "integer", rows = "numeric", cols = "numeric", name = "character", sign_str = "character", value = "ConstVal"),
                                    prototype(rows = 1, cols = 1, name = NA_character_, sign_str = UNKNOWN, value = NA_real_),
                      validity = function(object) {
                        if(!(object@sign_str %in% SIGN_STRINGS))
                          stop("[Sign: validation] sign_str must be in ", paste(SIGN_STRINGS, collapse = ", "))
                        else
                          return(TRUE)
                        }, contains = "Leaf")

#' @param rows The number of rows in the parameter.
#' @param cols The number of columns in the parameter.
#' @param name (Optional) A character string representing the name of the parameter.
#' @param sign (Optional) A character string indicating the sign of the parameter. Must be "ZERO", "POSITIVE", "NEGATIVE", or "UNKNOWN". Defaults to "UNKNOWN".
#' @param value (Optional) A numeric element, vector, matrix, or data.frame. Defaults to \code{NA} and may be changed with \code{value<-} later.
#' @rdname Parameter-class
#' @examples
#' x <- Parameter(3, name = "x0", sign="NEGATIVE") ## 3-vec negative
#' is_positive(x)
#' is_negative(x)
#' size(x)
#' @export
Parameter <- function(rows = 1, cols = 1, name = NA_character_, sign = UNKNOWN, value = NA_real_) {
  .Parameter(rows = rows, cols = cols, name = name, sign_str = toupper(sign), value = value)
}

setMethod("initialize", "Parameter", function(.Object, ..., id = get_id(), rows = 1, cols = 1, name = NA_character_, sign_str = UNKNOWN, value = NA_real_) {
  .Object@id <- id
  .Object@rows <- rows
  .Object@cols <- cols
  .Object@sign_str <- sign_str
  if(is.na(name))
    .Object@name <- sprintf("%s%s", PARAM_PREFIX, .Object@id)
  else
    .Object@name <- name

  # Initialize with value if provided
  .Object@value <- NA_real_
  if(!(length(value) == 1 && is.na(value)))
    value(.Object) <- value
  callNextMethod(.Object, ...)
})

setMethod("show", "Parameter", function(object) {
  cat("Parameter(", object@rows, ", ", object@cols, ", sign = ", sign(object), ")", sep = "")
})

#' @param x,object A \linkS4class{Parameter} object.
#' @rdname Parameter-class
setMethod("as.character", "Parameter", function(x) {
  paste("Parameter(", x@rows, ", ", x@cols, ", sign = ", sign(x), ")", sep = "")
})

#' @describeIn Parameter Returns \code{list(rows, cols, name, sign string, value)}.
setMethod("get_data", "Parameter", function(object) {
  list(rows = object@rows, cols = object@cols, name = object@name, sign_str = object@sign_str, value = object@value)
})

#' @describeIn Parameter The name of the parameter.
#' @export
setMethod("name", "Parameter", function(object) { object@name })

#' @describeIn Parameter The \code{c(rows, cols)} dimensions of the parameter.
setMethod("size", "Parameter", function(object) { c(object@rows, object@cols) })

#' @describeIn Parameter Is the parameter non-negative?
setMethod("is_positive", "Parameter", function(object) { object@sign_str == ZERO || toupper(object@sign_str) == POSITIVE })

#' @describeIn Parameter Is the parameter non-positive?
setMethod("is_negative", "Parameter", function(object) { object@sign_str == ZERO || toupper(object@sign_str) == NEGATIVE })

#' @describeIn Parameter An empty list since the gradient of a parameter is zero.
setMethod("grad", "Parameter", function(object) { list() })

#' @describeIn Parameter Returns itself as a parameter.
setMethod("parameters", "Parameter", function(object) { list(object) })

#' @describeIn Parameter The value of the parameter.
setMethod("value", "Parameter", function(object) { object@value })

#' @describeIn Parameter Set the value of the parameter.
setReplaceMethod("value", "Parameter", function(object, value) {
  object@value <- validate_val(object, value)
  object
})

#' @describeIn Parameter The canonical form of the parameter.
setMethod("canonicalize", "Parameter", function(object) {
  obj <- create_param(object, size(object))
  list(obj, list())
})

#'
#' The CallbackParam class.
#'
#' This class represents a parameter whose value is obtained by evaluating a function.
#'
#' @slot callback A numeric element, vector, matrix, or data.frame.
#' @name CallbackParam-class
#' @aliases CallbackParam
#' @rdname CallbackParam-class
.CallbackParam <- setClass("CallbackParam", representation(callback = "ConstVal"), contains = "Parameter")

#' @param callback A numeric element, vector, matrix, or data.frame
#' @param rows The number of rows in the parameter.
#' @param cols The number of columns in the parameter.
#' @param name (Optional) A character string representing the name of the parameter.
#' @param sign A character string indicating the sign of the parameter. Must be "ZERO", "POSITIVE", "NEGATIVE", or "UNKNOWN".
#' @rdname CallbackParam-class
#' @examples
#' x <- Variable(2)
#' dim <- size(x)
#' y <- CallbackParam(value(x), dim[1], dim[2], sign = "POSITIVE")
#' get_data(y)
#' @export
CallbackParam <- function(callback, rows = 1, cols = 1, name = NA_character_, sign = UNKNOWN) {
  .CallbackParam(callback = callback, rows = rows, cols = cols, name = name, sign_str = sign)
}

#' @param object A \linkS4class{CallbackParam} object.
#' @rdname CallbackParam-class
setMethod("value", "CallbackParam", function(object) { validate_val(object, value(object@callback)) })

#' @describeIn CallbackParam Returns \code{list(callback, rows, cols, name, sign string)}.
setMethod("get_data", "CallbackParam", function(object) {
  list(callback = object@callback, rows = object@rows, cols = object@cols, name = object@name, sign_str = object@sign_str)
})
