# Copyright 2012 Steven E. Pav. All Rights Reserved.
# Author: Steven E. Pav

# This file is part of SharpeR.
#
# SharpeR is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SharpeR is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with SharpeR.  If not, see <http://www.gnu.org/licenses/>.

# env var:
# nb: 
# see also:
# todo:
# changelog: 
#
# Created: 2012.05.19
# Copyright: Steven E. Pav, 2012-2013
# Author: Steven E. Pav
# Comments: Steven E. Pav
# SVN: $Id: blankheader.txt 25454 2012-02-14 23:35:25Z steven $

#' Inference on Sharpe ratio and Markowitz portfolio.
#' 
#' @section Sharpe Ratio: 
#'
#' Suppose \eqn{x_i}{xi} are \eqn{n} independent draws of a normal random
#' variable with mean \eqn{\mu}{mu} and variance \eqn{\sigma^2}{sigma^2}.
#' Let \eqn{\bar{x}}{xbar} be the sample mean, and \eqn{s} be
#' the sample standard deviation (using Bessel's correction). Let \eqn{c_0}{c0}
#' be the 'risk free rate'.  Then
#' \deqn{z = \frac{\bar{x} - c_0}{s}}{z = (xbar - c0)/s} 
#' is the (sample) Sharpe ratio.
#' 
#' The units of \eqn{z} is \eqn{\mbox{time}^{-1/2}}{per root time}.
#' Typically the Sharpe ratio is \emph{annualized} by multiplying by
#' \eqn{\sqrt{p}}{sqrt(p)}, where \eqn{p} is the number of observations
#' per year (or whatever the target annualization epoch.)
#'
#' Letting \eqn{z = \sqrt{p}\frac{\bar{x}-c_0}{s}}{z = sqrt(p)(xbar - c0)/s},
#' where the sample estimates are based on \eqn{n} observations, 
#' then \eqn{z}{z} takes a (non-central) Sharpe ratio distribution
#' parametrized by \eqn{n} 'degrees of freedom', non-centrality parameter
#' \eqn{\delta = \frac{\mu - c_0}{\sigma}}{delta = (mu - c0)/sigma}, and 
#' annualization parameter \eqn{p}. 
#'
#' The parameters are encoded as follows:
#' \itemize{
#' \item \eqn{n} is denoted by \code{df}.
#' \item \eqn{\delta}{delta} is denoted by \code{snr}.
#' \item \eqn{p} is denoted by \code{opy}. ('Observations Per Year')
#' }
#'
#' @section Maximal Sharpe Ratio: 
#'
#' Suppose \eqn{x_i}{xi} are \eqn{n} independent draws of a \eqn{q}-variate
#' normal random variable with mean \eqn{\mu}{mu} and covariance matrix
#' \eqn{\Sigma}{Sigma}. Let \eqn{\bar{x}}{xbar} be the (vector) sample mean, and 
#' \eqn{S} be the sample covariance matrix (using Bessel's correction). Let
#' \deqn{\zeta(w) = \frac{w^{\top}\bar{x} - c_0}{\sqrt{w^{\top}S w}}}{zeta(w) = (w'xbar - c0)/sqrt(w'Sw)}
#' be the (sample) Sharpe ratio of the portfolio \eqn{w}, subject to 
#' risk free rate \eqn{c_0}{c0}.
#'
#' Let \eqn{w_*}{w*} be the solution to the portfolio optimization problem:
#' \deqn{\max_{w: 0 < w^{\top}S w \le R^2} \zeta(w),}{max {zeta(w) | 0 < w'Sw <= R^2},}
#' with maximum value \eqn{z_* = \zeta\left(w_*\right)}{z* = zeta(w*)}.
#' Then 
#' \deqn{w_* = R \frac{S^{-1}\bar{x}}{\sqrt{\bar{x}^{\top}S^{-1}\bar{x}}}}{%
#' w* = R S^-1 xbar / sqrt(xbar' S^-1 xbar)}
#' and
#' \deqn{z_* = \sqrt{\bar{x}^{\top} S^{-1} \bar{x}} - \frac{c_0}{R}}{%
#' z* = sqrt(xbar' S^-1 xbar) - c0/R}
#'
#' The variable \eqn{z_*}{z*} follows a \emph{Maximal Sharpe ratio}
#' distribution. For convenience, we may assume that the sample statistic
#' has been annualized in the same manner as the Sharpe ratio, that is 
#' by multiplying by \eqn{p}, the number of observations per
#' epoch.
#' 
#' The Maximal Sharpe Ratio distribution is parametrized by the number of independent 
#' observations, \eqn{n}, the number of assets, \eqn{q}, the 
#' noncentrality parameter, 
#' \deqn{\delta = \sqrt{\mu^{\top}\Sigma^{-1}\mu},}{delta = sqrt(mu' Sigma^-1 mu),}
#' the 'drag' term, \eqn{c_0/R}{c0/R}, and the annualization factor, \eqn{p}.
#' The drag term makes this a location family of distributions, and 
#' by default we assume it is zero.
#' 
#' The parameters are encoded as follows:
#' \itemize{
#' \item \eqn{q} is denoted by \code{df1}.
#' \item \eqn{n} is denoted by \code{df2}.
#' \item \eqn{\delta} is denoted by \code{snrstar}.
#' \item \eqn{p} is denoted by \code{opy}.
#' \item \eqn{c_0/R} is denoted by \code{drag}.
#' }
#'
#' @author Steven E. Pav \email{shabbychef@@gmail.com}
#' @references
#'
#' Sharpe, William F. "Mutual fund performance." Journal of business (1966): 119-138.
#' \url{http://ideas.repec.org/a/ucp/jnlbus/v39y1965p119.html}
#' 
#' Lo, Andrew W. "The statistics of Sharpe ratios." Financial Analysts Journal 58, no. 4 
#' (2002): 36-52. \url{http://ssrn.com/paper=377260}
#'
#' Opdyke, J. D. "Comparing Sharpe Ratios: So Where are the p-values?" Journal of Asset
#' Management 8, no. 5 (2006): 308-336. \url{http://ssrn.com/paper=886728}
#'
#' Johnson, N. L., and Welch, B. L. "Applications of the non-central t-distribution."
#' Biometrika 31, no. 3-4 (1940): 362-389. \url{http://dx.doi.org/10.1093/biomet/31.3-4.362}
#'
#' Kan, Raymond and Smith, Daniel R. "The Distribution of the Sample Minimum-Variance Frontier."
#' Journal of Management Science 54, no. 7 (2008): 1364--1380.
#' \url{http://mansci.journal.informs.org/cgi/doi/10.1287/mnsc.1070.0852}
#'
#' Kan, Raymond and Zhou, GuoFu. "Tests of Mean-Variance Spanning."
#' Annals of Economics and Finance 13, no. 1 (2012)
#' \url{http://www.aeconf.net/Articles/May2012/aef130105.pdf}
#'
#' Britten-Jones, Mark. "The Sampling Error in Estimates of Mean-Variance 
#' Efficient Portfolio Weights." The Journal of Finance 54, no. 2 (1999):
#' 655--671. \url{http://www.jstor.org/stable/2697722}
#'
#' Silvapulle, Mervyn. J. "A Hotelling's T2-type statistic for testing against 
#' one-sided hypotheses." Journal of Multivariate Analysis 55, no. 2 (1995):
#' 312--319. \url{http://dx.doi.org/10.1006/jmva.1995.1081}
#'
#' Bodnar, Taras and Okhrin, Yarema. "On the Product of Inverse Wishart
#' and Normal Distributions with Applications to Discriminant Analysis 
#' and Portfolio Theory." Scandinavian Journal of Statistics 38, no. 2 (2011):
#' 311--331. \url{http://dx.doi.org/10.1111/j.1467-9469.2011.00729.x}
#'
#' @name SharpeR
#' @docType package
#' @title ...
#' @keywords package
#' @note The following are still in the works:
#' \enumerate{
#' \item Corrections for standard error based on skew, kurtosis and
#' autocorrelation.
#' \item Tests on Sharpe under positivity constraint. (\emph{c.f.} Silvapulle)
#' \item Portfolio spanning tests.
#' \item Tests on portfolio weights.
#' \item Tests of hedge restrictions.
#' }
#'
NULL
