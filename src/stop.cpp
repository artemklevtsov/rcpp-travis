#include <Rcpp.h>

// [[Rcpp::export(rng=false)]]
void do_stop_impl() {
  Rcpp::stop("Error");
}
