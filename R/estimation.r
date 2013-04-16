# Copyright 2012-2013 Steven E. Pav. All Rights Reserved.
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

#' @include utils.r
#' @include distributions.r

# note: on citations, use the Chicago style from google scholar. tks.

########################################################################
# Estimation 
########################################################################
# Sharpe Ratio#FOLDUP
#' @title Compute the Sharpe ratio.
#'
#' @description 
#'
#' Computes the Sharpe ratio of some observed returns.
#'
#' @details
#'
#' Suppose \eqn{x_i}{xi} are \eqn{n}{n} independent returns of some
#' asset.
#' Let \eqn{\bar{x}}{xbar} be the sample mean, and \eqn{s}{s} be
#' the sample standard deviation (using Bessel's correction). Let \eqn{c_0}{c0}
#' be the 'risk free rate'.  Then
#' \deqn{z = \frac{\bar{x} - c_0}{s}}{z = (xbar - c0)/s} 
#' is the (sample) Sharpe ratio.
#' 
#' The units of \eqn{z}{z} are \eqn{\mbox{time}^{-1/2}}{per root time}.
#' Typically the Sharpe ratio is \emph{annualized} by multiplying by
#' \eqn{\sqrt{\mbox{opy}}}{sqrt(opy)}, where \eqn{\mbox{opy}}{opy} 
#' is the number of observations
#' per year (or whatever the target annualization epoch.)
#'
#' @usage
#'
#' sr(x,...)
#' c0=0,opy=1,na.rm=FALSE)
#'
#' @param x vector of returns.
#' @param c0 the 'risk-free' or 'disastrous' rate of return. this is
#'        assumed to be given in the same units as x, \emph{not}
#'        in 'annualized' terms.
#' @param opy the number of observations per 'year'. This is used to
#'        'annualize' the answer.
#' @keywords univar 
#' @return a list containing the following components:
#' \item{sr}{the annualized Sharpe ratio.}
#' \item{df}{the number of observations.}
#' \item{opy}{the annualization factor.}
#' cast to class \code{sr}.
#' @seealso sr-distribution functions, \code{\link{dsr}, \link{psr}, \link{qsr}, \link{rsr}}
#' @rdname sr
#' @export sr
#' @author Steven E. Pav \email{shabbychef@@gmail.com}
#' @family sr
#' @references 
#'
#' Sharpe, William F. "Mutual fund performance." Journal of business (1966): 119-138.
#' \url{http://ideas.repec.org/a/ucp/jnlbus/v39y1965p119.html}
#' 
#' Lo, Andrew W. "The statistics of Sharpe ratios." Financial Analysts Journal (2002): 36-52.
#' \url{http://ssrn.com/paper=377260}
#'
#' @examples 
#' # Sharpe's 'model': just given a bunch of returns.
#' asr <- sr(rnorm(253*8),opy=253)
#' # given an xts object:
#' if (require(quantmod)) {
#'   getSymbols('IBM')
#'   lrets <- diff(log(IBM[,"IBM.Adjusted"]))
#'   asr <- sr(lrets,na.rm=TRUE)
#' }
#' # on a linear model, find the 'Sharpe' of the residual term
#' Factors <- matrix(rnorm(253*5*6),ncol=6)
#' Returns <- rnorm(dim(Factors)[1],0.003)
#' APT_mod <- lm(Returns ~ Factors)
#' asr <- sr(APT_mod,opy=253)
#'   
sr <- function(x,c0=0,opy=1,...) {
	UseMethod("sr", x)
}
# spawn a "SR" object.
# the Sharpe Ratio is a rescaled t-statistic.
#
# SR = R t
#
# where R is the 'rescaling', and
# t = (betahat' v - c0) / sigmahat
# is distributed as a non-central t with
# df degrees of freedom and non-centrality
# parameter
# delta = (beta' v - c0) / (sigma R)
#
# for 'convenience' we re-express SR and delta
# in 'annualized' units by multiplying them by
# sqrt(opy)
.spawn_sr <- function(sr,df,c0,opy,rescal) {
	retval <- list(sr = sr,df = df,c0 = c0,opy = opy,rescal = rescal)
	class(retval) <- "sr"
	return(retval)
}
# get the t-stat associated with an SR object.
.sr2t <- function(x) {
	tval <- x$sr / (x$rescal * sqrt(x$opy))
	return(tval)
}
# and the reverse
.t2sr <- function(x,tval) {
	srval <- tval * (x$rescal * sqrt(x$opy))
	return(srval)
}
.psr <- function(q,zeta,...) {
	retv <- prt(q$sr,df=q$df,K=(q$rescal * sqrt(q$opy)),rho=zeta,...)
	return(retv)
}
.dsr <- function(q,zeta,...) {
	retv <- drt(q$sr,df=q$df,K=(q$rescal * sqrt(q$opy)),rho=zeta,...)
	return(retv)
}

# compute SR in only one place. I hope.
.compute_sr <- function(mu,c0,sigma,opy) {
	sr <- (mu - c0) / sigma
	if (!missing(opy))
		sr <- sr * sqrt(opy)
	return(sr)
}
#'
#' @param na.rm logical.  Should missing values be removed?
#' @rdname sr
#' @method sr default
#' @S3method sr default
sr.default <- function(x,c0=0,opy=1,na.rm=FALSE) {
	mu <- mean(x,na.rm=na.rm)
	sigma <- sd(x,na.rm=na.rm)
	sr <- .compute_sr(mu,c0,sigma,opy)
	df <- ifelse(na.rm,sum(!is.na(x)),length(x))
	retval <- .spawn_sr(sr,df=df-1,c0=c0,opy=opy,rescal=1/sqrt(df))
	return(retval)
}
#'
#' @param x a fit model of class \code{lm}.
#' @rdname sr
#' @method sr lm 
#' @S3method sr lm
sr.lm <- function(x,c0=0,opy=1,na.rm=FALSE) {
	modl <- x
	mu <- modl$coefficients["(Intercept)"]
	sigma <- sqrt(deviance(modl) / modl$df.residual)
	sr <- .compute_sr(mu,c0,sigma,opy)
	XXinv <- vcov(modl) / sigma^2
	rescal <- sqrt(XXinv["(Intercept)","(Intercept)"])
	retval <- .spawn_sr(sr,df=modl$df.residual,c0=c0,opy=opy,rescal=rescal)
	return(retval)
}
#'
#' @param anxts an xts object.
#' @rdname sr
#' @method sr xts 
#' @S3method sr xts
sr.xts <- function(x,c0=0,opy=1,na.rm=FALSE) {
	anxts <- x
	if (missing(opy)) {
		TEO <- time(anxts)
		days.per.row <- as.double((TEO[length(TEO)] - TEO[1]) / (length(TEO) - 1))
		opy <- 365.25 / days.per.row
	}
	retval <- sr.default(anxts,c0=c0,opy=opy,na.rm=na.rm)
	return(retval)
}
#' @title Is this in the "sr" class?
#'
#' @description 
#'
#' Checks if an object is in the class \code{'sr'}
#'
#' @details
#'
#' To satisfy the minimum requirements of an S3 class.
#'
#' @usage
#'
#' is.sr(x)
#'
#' @param x an object of some kind.
#' @return a boolean.
#' @seealso sr
#' @author Steven E. Pav \email{shabbychef@@gmail.com}
#' @export
#'
#' @examples 
#' rvs <- sr(rnorm(253*8),opy=253)
#' is.sr(rvs)
is.sr <- function(x) inherits(x,"sr")

#' @S3method format sr
#' @export
format.sr <- function(x,...) {
	# oh! ugly! ugly!
	retval <- capture.output(print(x,...))
	return(retval)
}
#' @S3method print sr
#' @export
print.sr <- function(x,...) {
	tval <- .sr2t(x)
	pval <- pt(tval,x$df,lower.tail=FALSE)
	coefs <- cbind(x$sr,tval,pval)
	colnames(coefs) <- c("stat","t.stat","p.value")
	rownames(coefs) <- c("Sharpe")
	printCoefmat(coefs,P.values=TRUE,has.Pvalue=TRUE)
}

# print.sr <- function(x,...) cat(format(x,...), "\n")


# compute the markowitz portfolio
.markowitz <- function(X,mu=NULL,Sigma=NULL) {
	na.omit(X)
	if (is.null(mu)) 
		mu <- colMeans(X)
	if (is.null(Sigma)) 
		Sigma <- cov(X)
	w <- solve(Sigma,mu)
	n <- dim(X)[1]
	retval <- list(w = w, mu = mu, Sigma = Sigma, df1 = length(w), df2 = n)
	return(retval)
}

# compute Hotelling's statistic.
.hotelling <- function(X) {
	retval <- .markowitz(X)
	retval$T2 <- retval$df2 * (retval$mu %*% retval$w)
	return(retval)
}

#' @title Compute the Sharpe ratio of the Markowitz portfolio.
#'
#' @description 
#'
#' Computes the Sharpe ratio of the Markowitz portfolio of some observed returns.
#'
#' @details
#' 
#' Suppose \eqn{x_i}{xi} are \eqn{n}{n} independent draws of a \eqn{q}{q}-variate
#' normal random variable with mean \eqn{\mu}{mu} and covariance matrix
#' \eqn{\Sigma}{Sigma}. Let \eqn{\bar{x}}{xbar} be the (vector) sample mean, and 
#' \eqn{S}{S} be the sample covariance matrix (using Bessel's correction). Let
#' \deqn{\zeta(w) = \frac{w^{\top}\bar{x} - c_0}{\sqrt{w^{\top}S w}}}{zeta(w) = (w'xbar - c0)/sqrt(w'Sw)}
#' be the (sample) Sharpe ratio of the portfolio \eqn{w}{w}, subject to 
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
#' The units of \eqn{z_*}{z*} are \eqn{\mbox{time}^{-1/2}}{per root time}.
#' Typically the Sharpe ratio is \emph{annualized} by multiplying by
#' \eqn{\sqrt{\mbox{opy}}}{sqrt(opy)}, where \eqn{\mbox{opy}}{opy} 
#' is the number of observations
#' per year (or whatever the target annualization epoch.)
#'
#' @usage
#'
#' sropt(X,drag=0,opy=1)
#'
#' @param X matrix of returns.
#' @param drag the 'drag' term, \eqn{c_0/R}{c0/R}. defaults to 0. It is assumed
#'        that \code{drag} has been annualized, \emph{i.e.} has been multiplied
#'        by \eqn{\sqrt{opy}}{sqrt(opy)}. This is in contrast to the \code{c0}
#'        term given to \code{\link{sr}}.
#' @param opy the number of observations per 'year'. The returns are observed
#'        at a rate of \code{opy} per 'year.' default value is 1, meaning no 
#'        annualization is performed.
#' @keywords univar 
#' @return A list with containing the following components:
#' \item{w}{the optimal portfolio.}
#' \item{mu}{the estimated mean return vector.}
#' \item{Sigma}{the estimated covariance matrix.}
#' \item{df1}{the number of assets.}
#' \item{df2}{the number of observed vectors.}
#' \item{T2}{the Hotelling \eqn{T^2} statistic.}
#' \item{sropt}{the maximal Sharpe statistic.}
#' \item{drag}{the input \code{drag} term.}
#' \item{opy}{the input \code{opy} term.}
#' @aliases sropt
#' @seealso \code{\link{sr}}, sropt-distribution functions, 
#' \code{\link{dsropt}, \link{psropt}, \link{qsropt}, \link{rsropt}}
#' @export 
#' @author Steven E. Pav \email{shabbychef@@gmail.com}
#' @family sropt
#' @examples 
#' rvs <- sropt(matrix(rnorm(253*8*4),ncol=4),drag=0,opy=253)
#'
sropt <- function(X,drag=0,opy=1) {
	retval <- .hotelling(X)
	zeta.star <- sqrt(retval$T2 / retval$df2)
	if (!missing(opy))
		zeta.star <- .annualize(zeta.star,opy)
	retval$sropt <- zeta.star - drag

	#units(retval$sropt) <- "yr^-0.5"
	retval$drag <- drag
	retval$opy <- opy
	class(retval) <- "sropt"
	return(retval)
}
#UNFOLD

# confidence intervals on the non-centrality parameter of a t-stat


# See Walck, section 33.3
.t_se_weird <- function(tstat,df) {
	cn <- .tbias(df)
	dn <- tstat / cn
	se <- sqrt(((1+dn**2) * (df/df-2)) - tstat**2)
	return(se)
}
# See Walck, section 33.5
.t_se_normal <- function(tstat,df) {
	se <- sqrt(1 + (tstat**2) / (2*df))
	return(se)
}
.t_se <- function(t,df,type=c("t","Lo","exact")) {
	# 2FIX: add opdyke corrections for skew and kurtosis?
	# 2FIX: add autocorrelation correction?
	type <- match.arg(type)
	se <- switch(type,
							 t = .t_se_normal(t,df),
							 Lo = .t_se_normal(t,df),
							 exact = .t_se_weird(t,df))
	return(se)
}
# confidence intervals.
.t_confint <- function(tstat,df,level=0.95,type=c("exact","t","Z","F"),
					 level.lo=(1-level)/2,level.hi=1-level.lo) {
	type <- match.arg(type)
	if  (type == "exact") {
		ci.lo <- qlambdap(level.lo,df-1,tstat,lower.tail=TRUE)
		ci.hi <- qlambdap(level.hi,df-1,tstat,lower.tail=TRUE)
		ci <- c(ci.lo,ci.hi)
	} else if (type == "t") {
		se <- .t_se(tstat,df,type=type)
		midp <- tstat
		zalp <- qnorm(c(level.lo,level.hi))
		ci <- midp + zalp * se
	} else if (type == "Z") {
		se <- .t_se(tstat,df,type="t")
		midp <- tstat * (1 - 1 / (4 * df))
		zalp <- qnorm(c(level.lo,level.hi))
		ci <- midp + zalp * se
	} else if (type == "F") {
		# this is silly.
		se <- .t_se(tstat,df,type="exact")
		cn <- .tbias(df)
		midp <- z / cn
		zalp <- qnorm(c(level.lo,level.hi))
		ci <- midp + zalp * se
	} else stop("internal error")

	retval <- matrix(ci,nrow=1)
	colnames(retval) <- sapply(c(level.lo,level.hi),function(x) { sprintf("%g %%",100*x) })
	return(retval)
}



# confidence intervals on the Sharpe ratio#FOLDUP

# 2FIX: add documentation for 'se'
#' @title Standard error computation
#' @rdname se
#' @export
se <- function(x, ...) {
	UseMethod("se", x)
}
#'
#' @rdname se
#' @method se default
#' @S3method se default
se.default <- function(x, ...) {
	stop("no generic standard error computation available")
}
#' @title Standard error of Sharpe ratio
#'
#' @description 
#'
#' Estimates the standard error of the Sharpe ratio statistic. 
#'
#' @details 
#'
#' 2FIX; document
#' There are two methods:
#'
#' \itemize{
#' \item The default, \code{t}, based on Johnson & Welch, with a correction
#' for small sample size, also known as \code{Lo}.
#' \item A method based on the exact variance of the non-central t-distribution,
#' \code{exact}.
#' }
#' There should be very little difference between these except for very small
#' sample sizes.
#'
#' @usage
#'
#' se(z, type=c("t","Lo","exact"))
#'
#' @param z an observed Sharpe ratio statistic, of class \code{sr}.
#' @param type the estimator type. one of \code{"t", "Lo", "exact"}
#' @keywords htest
#' @return an estimate of standard error.
#' @seealso sr-distribution functions, \code{\link{dsr}}
#' @export 
#' @author Steven E. Pav \email{shabbychef@@gmail.com}
#' @family sr
#' @rdname se
#' @note
#' Eventually this should include corrections for autocorrelation, skew,
#' kurtosis.
#' @references 
#'
#' Walck, C. "Hand-book on STATISTICAL DISTRIBUTIONS for experimentalists."
#' 1996. \url{http://www.stat.rice.edu/~dobelman/textfiles/DistributionsHandbook.pdf}
#'
#' Johnson, N. L., and Welch, B. L. "Applications of the non-central t-distribution."
#' Biometrika 31, no. 3-4 (1940): 362-389. \url{http://dx.doi.org/10.1093/biomet/31.3-4.362}
#'
#' Lo, Andrew W. "The statistics of Sharpe ratios." Financial Analysts Journal 58, no. 4 
#' (2002): 36-52. \url{http://ssrn.com/paper=377260}
#'
#' Opdyke, J. D. "Comparing Sharpe Ratios: So Where are the p-values?" Journal of Asset
#' Management 8, no. 5 (2006): 308-336. \url{http://ssrn.com/paper=886728}
#'
#' @examples 
#' asr <- sr(rnorm(1000,0.2))
#' anse <- se(asr,type="t")
#' anse2 <- se(asr,type="exact")
#'
#'@export
#'
#' @method se sr
#' @S3method se sr
se.sr <- function(z, type=c("t","Lo","exact")) {
	tstat <- .sr2t(z)
	retval <- .t_se(tstat,df=z$df,type=type)
	retval <- .t2sr(z,retval)
	return(retval)
}

#' @title Confidence Interval on Signal-Noise Ratio
#'
#' @description 
#'
#' Computes approximate confidence intervals on the Signal-Noise ratio given the Sharpe ratio.
#'
#' @details 
#'
#' Constructs confidence intervals on the Signal-Noise ratio given observed
#' Sharpe ratio statistic. The available methods are:
#'
#' \itemize{
#' \item The default, \code{exact}, which is only exact when returns are
#' normal, based on inverting the non-central t
#' distribution.
#' \item A method based on the standard error of a non-central t distribution.
#' \item A method based on a normal approximation.
#' \item A method based on an F statistic.
#' }
#'
#' @usage
#'
#' confint(z,parm,level=0.95,...)
#'
#' @param z an observed Sharpe ratio statistic, of class \code{sr}.
#' @param parm ignored here
#' @param level the confidence level required.
#' @param ... the following parameters are relevant:
#' \itemize{
#' \item \code{type} is oe of \code{c("exact","t","Z","F")}
#' \item \code{level.lo}, and \code{level.hi} allow one to compute
#' non-symmetric CI.
#' }
#' @keywords htest
#' @return A matrix (or vector) with columns giving lower and upper
#' confidence limits for the SNR. These will be labelled as
#' level.lo and level.hi in \%, \emph{e.g.} \code{"2.5 \%"}
#' @seealso \code{\link{confint}}, \code{\link{se}}, \code{\link{qlambdap}}
#' @export 
#' @author Steven E. Pav \email{shabbychef@@gmail.com}
#' @family sr
#' @examples 
#' # using "sr" class:
#' opy <- 253
#' df <- opy * 6
#' xv <- rnorm(df, 1 / sqrt(opy))
#' mysr <- sr(xv)
#' confint(mysr,level=0.90)
#'
#' @rdname confint
#' @method confint sr 
#' @S3method confint sr 
confint.sr <- function(z,parm,level=0.95,...) {
	tstat <- .sr2t(z)
	retval <- .t_confint(tstat,df=z$df,level=level,...)
	retval <- .t2sr(z,retval)
	return(retval)
}
											 
#' @title Confidence Interval on Maximal Signal-Noise Ratio
#'
#' @description 
#'
#' Computes approximate confidence intervals on the Signal-Noise ratio given the Sharpe ratio.
#'
#' @details 
#'
#' Suppose \eqn{x_i}{xi} are \eqn{n}{n} independent draws of a \eqn{q}{q}-variate
#' normal random variable with mean \eqn{\mu}{mu} and covariance matrix
#' \eqn{\Sigma}{Sigma}. Let \eqn{\bar{x}}{xbar} be the (vector) sample mean, and 
#' \eqn{S}{S} be the sample covariance matrix (using Bessel's correction). 
#' Let 
#' \deqn{z_* = \sqrt{\bar{x}^{\top} S^{-1} \bar{x}}}{z* = sqrt(xbar' S^-1 xbar)}
#' Given observations of \eqn{z_*}{z*}, compute confidence intervals on the
#' population analogue, defined as
#' \deqn{\zeta_* = \sqrt{\mu^{\top} \Sigma^{-1} \mu}}{zeta* = sqrt(mu' Sigma^-1 mu)}
#'
#' @usage
#'
#' sropt_confint(z.s,df1,df2,level=0.95,
#'                opy=1,level.lo=(1-level)/2,level.hi=1-level.lo)
#'
#' @param z.s an observed Sharpe ratio statistic, annualized.
#' @inheritParams qco_sropt
#' @inheritParams dsropt
#' @inheritParams qsropt
#' @inheritParams psropt
#' @param level the confidence level required.
#' @param opy the number of observations per 'year'. \code{x}, \code{q}, and 
#'        \code{snr} are quoted in 'annualized' units, that is, per square root 
#'        'year', but returns are observed possibly at a rate of \code{opy} per 
#'        'year.' default value is 1, meaning no deannualization is performed.
#' @param level.lo the lower bound for the confidence interval.
#' @param level.hi the upper bound for the confidence interval.
#' @keywords htest
#' @return A matrix (or vector) with columns giving lower and upper
#' confidence limits for the SNR. These will be labelled as
#' level.lo and level.hi in \%, \emph{e.g.} \code{"2.5 \%"}
#' @seealso \code{\link{confint}}, \code{\link{qco_sropt}}, \code{\link{sropt.test}}
#' @export 
#' @author Steven E. Pav \email{shabbychef@@gmail.com}
#' @family sropt
#' @rdname sropt_confint
#' @examples 
#' # fix these!
#' opy <- 253
#' df1 <- 6
#' df2 <- opy * 6
#' rvs <- as.matrix(rnorm(df1*df2),ncol=df1)
#' sro <- sropt(rvs)
#' aci <- confint(sro)
#'
#'@export
sropt_confint <- function(z.s,df1,df2,level=0.95,
											     opy=1,level.lo=(1-level)/2,level.hi=1-level.lo) {
	#2FIX: the order of arguments is really wonky. where does opy go?
	#if (!missing(opy)) {
		#z.s <- .deannualize(z.s,opy)
	#}

	ci.hi <- qco_sropt(level.hi,df1=df1,df2=df2,z.s=z.s,opy=opy,lower.tail=TRUE)
	ci.lo <- qco_sropt(level.lo,df1=df1,df2=df2,z.s=z.s,opy=opy,lower.tail=TRUE,ub=ci.hi)
	ci <- c(ci.lo,ci.hi)

	retval <- matrix(ci,nrow=1)
	colnames(retval) <- sapply(c(level.lo,level.hi),function(x) { sprintf("%g %%",100*x) })
	return(retval)
}
#' @export
#' @param parm ignored here
#' @rdname sropt_confint
#' @method confint sropt
#' @S3method confint sropt
confint.sropt <- function(z,parm,level=0.95,...) {
	retval <- sropt_confint(z$sropt,z$df1,z$df2,level=level,opy=z$opy,...)
	return(retval)
}

#UNFOLD

# point inference on sropt/ncp of F#FOLDUP

# compute an unbiased estimator of the non-centrality parameter
.F_ncp_unbiased <- function(Fs,df1,df2) {
	ncp.unb <- (Fs * (df2 - 2) * df1 / df2) - df1
	return(ncp.unb)
}

#MLE of the ncp based on a single F-stat
.F_ncp_MLE_single <- function(Fs,df1,df2,ub=NULL,lb=0) {
	if (Fs <= 1) { return(0.0) }  # Spruill's Thm 3.1, eqn 8
	max.func <- function(z) { df(Fs,df1,df2,ncp=z,log=TRUE) }

	if (is.null(ub)) {
		prevdpf <- -Inf
		ub <- 1
		dpf <- max.func(ub)
		while (prevdpf < dpf) {
			prevdpf <- dpf
			ub <- 2 * ub
			dpf <- max.func(ub)
		}
		lb <- ifelse(ub > 2,ub/4,lb)
	}
	ncp.MLE <- optimize(max.func,c(lb,ub),maximum=TRUE)$maximum;
	return(ncp.MLE)
}
.F_ncp_MLE <- Vectorize(.F_ncp_MLE_single,
											vectorize.args = c("Fs","df1","df2"),
											SIMPLIFY = TRUE)

# KRS estimator of the ncp based on a single F-stat
.F_ncp_KRS <- function(Fs,df1,df2) {
	xbs <- Fs * (df1/df2)
	delta0 <- (df2 - 2) * xbs - df1
	phi2 <- 2 * xbs * (df2 - 2) / (df1 + 2)
	delta2 <- pmax(delta0,phi2)
	return(delta2)
}

#' @export 
F.inference <- function(Fs,df1,df2,type=c("KRS","MLE","unbiased")) {
	# type defaults to "KRS":
	type <- match.arg(type)
	Fncp <- switch(type,
								 MLE = .F_ncp_MLE(Fs,df1,df2),
								 KRS = .F_ncp_KRS(Fs,df1,df2),
								 unbiased = .F_ncp_unbiased(Fs,df1,df2))
	return(Fncp)
}
#' @export 
T2.inference <- function(T2,df1,df2,...) {
	Fs <- .T2_to_F(T2, df1, df2)
	Fdf1 <- df1
	Fdf2 <- df2 - df1
	retv <- F.inference(Fs,Fdf1,Fdf2,...)
	# the NCP is legit
	retv <- retv
	return(retv)
}
#' @title Inference on noncentrality parameter of F or F-like statistic 
#'
#' @description 
#'
#' Estimates the non-centrality parameter associated with an observed
#' statistic following a (non-central) F, \eqn{T^2}, or sropt distribution. 
#'
#' @details 
#'
#' Let \eqn{F}{F} be an observed statistic distributed as a non-central F with 
#' \eqn{\nu_1}{df1}, \eqn{\nu_2}{df2} degrees of freedom and non-centrality 
#' parameter \eqn{\delta^2}{delta^2}. Three methods are presented to
#' estimate the non-centrality parameter from the statistic:
#'
#' \itemize{
#' \item an unbiased estimator, which, unfortunately, may be negative.
#' \item the Maximum Likelihood Estimator, which may be zero, but not
#' negative.
#' \item the estimator of Kubokawa, Roberts, and Shaleh (KRS), which
#' is a shrinkage estimator.
#' }
#'
#' Since a Hotelling distribution is equivalent to the F-distribution
#' up to scaling, the same estimators can be used to estimate the 
#' non-centrality parameter of a non-central Hotelling T-squared statistic.
#'
#' The sropt distribution is equivalent to a Hotelling up to a 
#' square root and some rescalings. 
#' 
#' The non-centrality parameter of the sropt distribution is 
#' the square root of that of the Hotelling, \emph{i.e.} has
#' units 'per square root time'. As such, the \code{'unbiased'}
#' type can be problematic!
#'
#' @usage
#'
#' F.inference(Fs, df1, df2, type=c("KRS","MLE","unbiased"))
#'
#' T2.inference(T2,df1,df2,...) 
#'
#' sropt.inference(z.s,df1,df2,opy=1,drag=0,...)
#'
#' @param Fs a (non-central) F statistic.
#' @param T2 a (non-central) Hotelling \eqn{T^2} statistic.
#' @param z.s an observed Sharpe ratio statistic, annualized.
#' @inheritParams qco_sropt
#' @inheritParams dsropt
#' @inheritParams qsropt
#' @inheritParams psropt
#' @param type the estimator type. one of \code{c("KRS", "MLE", "unbiased")}
#' @param opy the number of observations per 'year'. \code{z.s} is  
#'        assumed given in 'annualized' units, that is, per 'year',
#'        but returns are observed possibly at a rate of \code{opy} per 
#'        'year.' default value is 1, meaning no deannualization is performed.
#' @param drag the 'drag' term, \eqn{c_0/R}{c0/R}. defaults to 0. It is assumed
#'        that \code{drag} has been annualized, \emph{i.e.} is given in the
#'        same units as \code{z.s}.
#' @param ... the \code{type} which is passed on to \code{F.inference}.
#' @keywords htest
#' @return an estimate of the non-centrality parameter.
#' @aliases F.inference T2.inference sropt.inference
#' @seealso F-distribution functions, \code{\link{df}}
#' @export 
#' @author Steven E. Pav \email{shabbychef@@gmail.com}
#' @family sropt Hotelling
#' @references 
#'
#' Kubokawa, T., C. P. Robert, and A. K. Saleh. "Estimation of noncentrality parameters." 
#' Canadian Journal of Statistics 21, no. 1 (1993): 45-57. \url{http://www.jstor.org/stable/3315657}
#'
#' Spruill, M. C. "Computation of the maximum likelihood estimate of a noncentrality parameter." 
#' Journal of multivariate analysis 18, no. 2 (1986): 216-224.
#' \url{http://www.sciencedirect.com/science/article/pii/0047259X86900709}
#'
#' @examples 
#' rvs <- rf(1024, 4, 1000, 5)
#' unbs <- F.inference(rvs, 4, 1000, type="unbiased")
#' # generate some sropts
#' true.snrstar <- 1.25
#' df1 <- 6
#' df2 <- 2000
#' opy <- 253
#' rvs <- rsropt(500, df1, df2, true.snrstar, opy)
#' est1 <- sropt.inference(rvs,df1,df2,opy,type='unbiased')  
#' est2 <- sropt.inference(rvs,df1,df2,opy,type='KRS')  
#' est3 <- sropt.inference(rvs,df1,df2,opy,type='MLE')
#'
sropt.inference <- function(z.s,df1,df2,opy=1,drag=0,...) {
	if (!missing(drag) && (drag != 0)) 
		z.s <- z.s + drag
	if (!missing(opy)) 
		z.s <- .deannualize(z.s, opy)
	T2 <- .sropt_to_T2(z.s, df2)
	retval <- T2.inference(T2,df1,df2,...)
	# convert back
	retval <- .T2_to_sropt(retval, df2)
	if (!missing(opy)) 
		retval <- .annualize(retval, opy)
	if (!missing(drag) && (drag != 0)) 
		retval <- retval - drag
	return(retval)
}
#UNFOLD

# notes:
# extract statistics (t-stat) from lm object:
# https://stat.ethz.ch/pipermail/r-help/2009-February/190021.html
#
# also: 
# see the code in summary.lm to see how sigma is calculated
# or
# sigma <- sqrt(deviance(fit) / df.residual(fit))
# then base on confint? coef/vcov

# to get a hotelling statistic from n x k matrix x:
# myt <- summary(manova(lm(x ~ 1)),test="Hotelling-Lawley",intercept=TRUE)
#              Df Hotelling-Lawley approx F num Df den Df Pr(>F)
#(Intercept)   1          0.00606     1.21      5    995    0.3
#
# HLT <- myt$stats[1,"Hotelling-Lawley"]
#
# myt <- summary(manova(lm(x ~ 1)),intercept=TRUE)
# HLT <- sum(myt$Eigenvalues) #?
# ...
# 

## junkyard#FOLDUP

##compute the asymptotic mean and variance of the sqrt of a
##non-central F distribution

#f_sqrt_ncf_asym_mu <- function(df1,df2,ncp = 0) {
	#return(sqrt((df2 / (df2 - 2)) * (df1 + ncp) / df1))
#}
#f_sqrt_ncf_asym_var <- function(df1,df2,ncp = 0) {
	#return((1 / (2 * df1)) * 
				 #(((df1 + ncp) / (df2 - 2)) + (2 * ncp + df1) / (df1 + ncp)))
#}
#f_sqrt_ncf_apx_pow <- function(df1,df2,ncp,alpha = 0.05) {
	#zalp <- qnorm(1 - alpha)
	#numr <- 1 - f_sqrt_ncf_asym_mu(df1,df2,ncp = ncp) + zalp / sqrt(2 * df1)
	#deno <- sqrt(f_sqrt_ncf_asym_var(df1,df2,ncp = ncp))
	#return(1 - pnorm(numr / deno))
#}
##UNFOLD

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
