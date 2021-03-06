% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generics.R
\docType{methods}
\name{canonicalize}
\alias{canonicalize}
\alias{canonicalize}
\alias{canonical_form}
\title{Canonicalize}
\usage{
canonicalize(object)

canonical_form(object)
}
\arguments{
\item{object}{A \linkS4class{Canonical} object.}
}
\value{
A list of \code{list(affine expression, list(constraints))}.
}
\description{
Computes the graph implementation of a canonical expression.
}
