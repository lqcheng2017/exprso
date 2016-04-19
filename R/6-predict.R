###########################################################
### Duplicate feature selection history

#' Duplicate Feature Selection History
#'
#' Duplicates the feature selection history of a reference \code{ExprsArray} object.
#'  Called directly by \code{predict.ExprsMachine} and indirectly by
#'  \code{predict.ExprsModule}. Ensures that the validation set has undergone
#'  the same process of feature selection and dimension reduction as the
#'  training set.
#'
#' @seealso
#' \code{\link{exprso-predict}}
#' @export
setGeneric("modHistory",
           function(object, ...) standardGeneric("modHistory")
)

#' @describeIn modHistory
#' @param object An \code{ExprsArray} object. The validation set that should undergo
#'  feature selection and dimension reduction.
#' @param reference An \code{ExprsArray} or \code{ExprsModel} object. The object with
#'  feature selection history used as a template for the validation set.
#' @export
setMethod("modHistory", "ExprsArray",
          function(object, reference){

            if(!is.null(object@preFilter)){

              # If reference@preFilter has less (or equal) history than object@preFilter
              if(length(reference@preFilter) <= length(object@preFilter)){

                stop("The provided object does not have less history than the reference object.")
              }

              # If history of reference@preFilter is not also in the object@preFilter
              if(!identical(object@preFilter, reference@preFilter[1:length(object@preFilter)])){

                stop("The provided object history does not match the reference history.")
              }
            }

            # Index first non-overlapping history
            index <- length(object@reductionModel) + 1

            # Manipulate object according to history stored in reference
            for(i in index:length(reference@reductionModel)){

              # If the i-th fs did NOT involve dimension reduction
              if(any(is.na(reference@reductionModel[[i]]))){

                # Build new object
                object <- new(class(object),
                              exprs = object@exprs[reference@preFilter[[i]], , drop = FALSE], # Update @exprs
                              annot = object@annot, # Preserve @annot
                              preFilter = append(object@preFilter, list(reference@preFilter[[i]])), # Append history
                              reductionModel = append(object@reductionModel, list(reference@reductionModel[[i]])))

              }else{

                # Build data according to the i-th probe set
                data <- data.frame(t(object@exprs[reference@preFilter[[i]], ]))

                # Then, apply the i-th reduction model
                comps <- predict(reference@reductionModel[[i]], data)

                # Build new object
                object <- new(class(object),
                              exprs = t(comps), # Update @exprs
                              annot = object@annot, # Preserve @annot
                              preFilter = append(object@preFilter, list(reference@preFilter[[i]])), # Append history
                              reductionModel = append(object@reductionModel, list(reference@reductionModel[[i]])))
              }
            }

            return(object)
          }
)

###########################################################
### Predict class labels using ExprsModel

#' @name exprso-predict
#'
#' Predict Class Labels
#'
#' Predict class labels of a validation set.
#'
#' An \code{ExprsMachine} object can only predict against an \code{ExprsBinary}
#'  object. An \code{ExprsModule} object can only predict against an
#'  \code{ExprsMulti} object. The validation set should never get modified
#'  once separated from the training set. If the training set used to build
#'  an \code{ExprsModule} had a class missing (i.e. a NULL placeholder),
#'  the \code{ExprsModule} cannot predict the missing class. As with
#'  all functions included in this package, ties get resolved using
#'  probability weights based on the relative frequency of the tied
#'  classes.
#'
#' \code{ExprsPredict} objects store predictions in three slots: \code{@@pred},
#'  \code{@@decision.values}, and \code{@@probability}. The first slot
#'  stores a "final decision" based on the class label with the maximum
#'  predicted probability. The second slot stores a transformation
#'  of the predicted probability for each class calculated by the inverse
#'  of Platt scaling. The predicted probability gets returned by the
#'  \code{predict} method called using the stored \code{@@mach} object.
#'  To learn how these slots get used to calculate classifier performance,
#'  read more at \code{\link{calcStats}}.
#'
#' @seealso
#' \code{\link{modHistory}}, \code{\link{calcStats}}
#' @export
NULL

#' @describeIn exprso-predict
#' @param object An \code{ExprsModel} object. The classifier to deploy.
#' @param array An \code{ExprsArray} object. The validation set.
#' @param verbose A logical scalar. Toggles whether to print \code{calcStats}.
#' @import e1071 MASS nnet randomForest
#' @export
setMethod("predict", "ExprsMachine",
          function(object, array, verbose = TRUE){

            if(class(array) != "ExprsBinary"){

              stop("Uh oh! You can only use an ExprsMachine to predict on an ExprsBinary object.")
            }

            # Reproduce the history stored in the ExprsMachine object
            array <- modHistory(array, reference = object)

            # Build data from modHistory output
            data <- data.frame(t(array@exprs))

            if("naiveBayes" %in% class(object@mach)){

              px <- predict(object@mach, data, type = "raw")
            }

            if("lda" %in% class(object@mach)){

              pred <- predict(object@mach, data)
              px <- pred$posterior
            }

            if("svm" %in% class(object@mach)){

              pred <- predict(object@mach, data, probability = TRUE)
              px <- attr(pred, "probabilities")

            }

            if("nnet" %in% class(object@mach)){

              px <- predict(object@mach, data, type = "raw")
              px <- cbind(px, 1 - px)
              colnames(px) <- c("Case", "Control") # do not delete this line!
            }

            if("randomForest" %in% class(object@mach)){

              px <- unclass(predict(object@mach, data, type = "prob"))
            }

            # Calculate 'decision.values' from 'probability' using inverse Platt scaling
            px <- as.data.frame(px)
            px <- px[, c("Control", "Case")]
            dv <- as.matrix(log(1 / (1 - px[, "Case"]) - 1))
            colnames(dv) <- "Case/Control"

            # Assign binary values based on probability
            pred <- vector("character", nrow(px))
            pred[px$Case > .5] <- "Case"
            pred[px$Case < .5] <- "Control"

            # Break ties randomly
            case <- sum(array@annot$defineCase == "Case") / nrow(array@annot)
            pred[px$Case == .5] <- sample(c("Case", "Control"), sum(px$Case == .5), TRUE, prob = c(case, 1 - case))

            # Clean up pred
            pred <- factor(as.vector(pred), levels = c("Control", "Case"))
            names(pred) <- rownames(data)

            final <- new("ExprsPredict", pred = pred, decision.values = dv, probability = as.matrix(px))

            if(verbose){

              cat("Individual classifier performance:\n")
              print(calcStats(final, array, aucSkip = TRUE, plotSkip = TRUE))
            }

            return(final)
          }
)

#' @describeIn exprso-predict
#' @export
setMethod("predict", "ExprsModule",
          function(object, array, verbose = TRUE){

            if(class(array) != "ExprsMulti"){

              stop("Uh oh! You can only use an ExprsModule to predict on an ExprsMulti object.")
            }

            if(length(object@mach) != length(levels(array@annot$defineCase))){

              stop("Uh oh! ExprsModule and ExprsMulti must have same number of classes.")
            }

            # Initialize preds container
            preds <- vector("list", length(object@mach))

            # For each ExprsMachine stored in @mach
            for(i in 1:length(object@mach)){

              # If the i-th ExprsMachine is missing due to lack of cases during build phase
              if(is.null(object@mach[[i]])){

                cat("The ExprsMachine corresponding to class", i, "is missing. Setting probability to 0.\n")
                missingCase <- rep(0, nrow(array@annot))
                preds[[i]] <- new("ExprsPredict", pred = as.factor(missingCase), decision.values = as.matrix(missingCase),
                                  probability = as.matrix(data.frame("Control" = missingCase, "Case" = missingCase)))
              }else{

                # Turn the ExprsMulti object into the i-th ExprsBinary object
                array.i <- array
                array.i@annot$defineCase <- ifelse(as.numeric(array.i@annot$defineCase) == i, "Case", "Control")
                class(array.i) <- "ExprsBinary"

                # Predict the i-th ExprsBinary with the i-th ExprsMachine
                cat("Performing a one-vs-all ExprsMachine prediction with class", i, "set as \"Case\".\n")
                preds[[i]] <- predict(object@mach[[i]], array.i)
              }
            }

            # Calculate 'decision.values' from 'probability' using inverse Platt scaling
            px <- lapply(preds, function(p) p@probability[, "Case", drop = FALSE])
            dv <- lapply(px, function(prob) log(1 / (1 - prob) - 1))
            px <- do.call(cbind, px); colnames(px) <- 1:ncol(px)
            dv <- do.call(cbind, dv); colnames(dv) <- 1:ncol(dv)

            # Initialize pred container
            pred <- vector("character", nrow(px))

            # calculate weight vector for random sampling during ties
            tieBreaker <- sapply(1:ncol(px), function(case) sum(array@annot$defineCase == case)) / nrow(array@annot)

            # Assign classes based on maximum probability
            for(i in 1:nrow(px)){

              # Index maximum probabilities for the i-th subject
              max.i <- which(px[i, ] == max(px[i, ]))

              # If no tie
              if(length(max.i) == 1){

                # Select class with maximum probability
                pred[i] <- as.character(which.max(px[i, ]))

              }else{

                # If none of the tied classes appear in test set, sample of all classes
                if(all(tieBreaker[max.i] %in% 0)) max.i <- 1:ncol(px)

                # Take weighted sample based on weight vector
                pred[i] <- sample(levels(array@annot$defineCase)[max.i], prob = tieBreaker[max.i])
              }
            }

            # Clean up pred
            pred <- factor(as.numeric(pred), levels = 1:ncol(px))

            final <- new("ExprsPredict", pred = pred, decision.values = dv, probability = px)

            if(verbose){

              cat("Multi-class classifier performance:\n")
              print(calcStats(final, array, aucSkip = TRUE, plotSkip = TRUE))
            }

            return(final)
          }
)

###########################################################
### Calculate classifier performance

#' Calculate Classifier Performance
#'
#' \code{calcStats} calculates classifier performance based on class predictions
#'  stored in an \code{ExprsPredict} object and the actual class labels stored
#'  in an \code{ExprsArray} object.
#'
#' The appropriate use of \code{calcStats} requires the \code{ExprsPredict} object
#'  to have derived from the same \code{ExprsArray} object used for the \code{array}
#'  argument. This function calculates classifier performance based on the predicted
#'  class labels and the actual class labels in one of two ways. If the argument
#'  \code{aucSkip = FALSE} *and* the \code{ExprsArray} object is an \code{ExprsBinary}
#'  object with at least one case and one control *and* \code{ExprsPredict} contains
#'  a coherent \code{@@probability} slot, \code{calcStats} will calculate classifier
#'  performance using the area under the receiver operating characteristic (ROCR) curve
#'  via the \code{ROCR} package. Otherwise, \code{calcStats} will calculate classifier
#'  performance traditionally using a confusion matrix. Note that accuracies calculated
#'  using \code{ROCR} may differ from accuracies calculated using a confusion
#'  matrix because the former may adjust the discrimination threshold to optimize
#'  sensitivity and specificity. The discrimination threshold is automatically chosen
#'  as the point along the ROC which minimizes the Euclidean distance from (0, 1).
#'
#' @seealso
#' \code{\link{exprso-predict}}
#' @export
setGeneric("calcStats",
           function(object, ...) standardGeneric("calcStats")
)

#' @describeIn calcStats
#' @param object An \code{ExprsPredict} object.
#' @param array An \code{ExprsArray} object. The data object used to produce the
#'  \code{ExprsPredict} object.
#' @param aucSkip A logical scalar. Toggles whether to calculate area under the
#'  receiver operating characteristic curve. See details.
#' @param plotSkip A logical scalar. Toggles whether to plot the receiver
#'  operating characteristic curve.
#' @import ROCR
#' @export
setMethod("calcStats", "ExprsPredict",
          function(object, array, aucSkip = FALSE, plotSkip = FALSE){

            if(!inherits(array, "ExprsArray")){

              stop("Uh oh! You can only assess the performance of a classifier using an ExprsArray object.")
            }

            if(class(array) == "ExprsMulti"){

              if(length(levels(object@pred)) != length(levels(array@annot$defineCase))){

                stop("Uh oh! ExprsPredict and ExprsMulti must have same number of classes.")
              }
            }

            # If predicted set contains only two classes, ExprsPredict has @probability, and aucSkip = FALSE
            if(all(c("Case", "Control") %in% array@annot$defineCase) & !is.null(object@probability) & !aucSkip){

              layout(matrix(c(1), 1, 1, byrow = TRUE))

              cat("Calculating accuracy using ROCR based on prediction probabilities...\n")
              p <- ROCR::prediction(object@probability[, "Case"], as.numeric(array@annot$defineCase == "Case"))

              # Plot AUC curve
              perf <- ROCR::performance(p, measure = "tpr", x.measure = "fpr")
              if(!plotSkip) plot(perf, col = rainbow(10))

              # Index optimal cutoff based on Euclidean distance
              index <- which.min(sqrt((1 - perf@y.values[[1]])^2 + (0 - perf@x.values[[1]])^2))

              # Calculate performance metrics
              acc <- ROCR::performance(p, "acc")@y.values[[1]][index]
              sens <- ROCR::performance(p, "sens")@y.values[[1]][index]
              spec <- ROCR::performance(p, "spec")@y.values[[1]][index]
              auc <- ROCR::performance(p, "auc")@y.values[[1]]

              return(data.frame(acc, sens, spec, auc))

            }else{

              cat("Arguments not provided in an ROCR AUC format. Calculating accuracy outside of ROCR...\n")

              # Turn ExprsBinary $defineCase into factor
              if(class(array) == "ExprsBinary"){

                array@annot$defineCase <- factor(array@annot$defineCase, levels = c("Control", "Case"))
              }

              # Build confusion table
              table <- table("predicted" = object@pred, "actual" = array@annot$defineCase)
              cat("Classification confusion table:\n"); print(table)

              # Compute per-class performance
              for(class in 1:nrow(table)){

                tp <- sum(table[row(table) == col(table)][class])
                tn <- sum(table[row(table) == col(table)][-class])
                fp <- sum(table[row(table) == class & col(table) != class]) # called class but not
                fn <- sum(table[row(table) != class & col(table) == class]) # is but not called
                acc <- (tp + tn) / (tp + tn + fp + fn)
                sens <- tp / (tp + fn)
                spec <- tn / (fp + tn)

                # If multi-class
                if(class(array) == "ExprsMulti"){

                  cat("Class", class, "performance (acc, sens, spec):", paste0(acc,", ",sens,", ", spec), "\n")

                }else{

                  # NOTE: class == 2 refers to "Case"
                  if(class == 2) return(data.frame(acc, sens, spec))
                }
              }

              # Compute total accuracy
              tp <- sum(table[row(table) == col(table)])
              tn <- sum(table[row(table) == col(table)])
              fp <- sum(table[row(table) != col(table)])
              fn <- sum(table[row(table) != col(table)])
              acc <- (tp + tn) / (tp + tn + fp + fn)

              cat("Total accuracy of ExprsModule:", acc, "\n")

              return(data.frame(acc))
            }
          }
)