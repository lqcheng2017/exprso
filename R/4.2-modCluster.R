##########################################################
### Cluster subjects by feature data

#' Cluster Subjects
#'
#' This method clusters subjects based on expression data using any one of
#'  several available clustering algorithms. See Arguments below for details.
#'
#' @param object An \code{ExprsArray object}. The object containing
#'  the subject data to cluster.
#'
#' @export
setGeneric("modCluster",
           function(object, ...) standardGeneric("modCluster")
)

#' @describeIn modCluster Method to compare \code{ExprsArray} objects.
#'
#' @param probes A numeric scalar or character vector. A numeric scalar indicates
#'  the number of top features that should guide clustering. A character vector
#'  indicates specifically which features by name should guide clustering.
#'  Set \code{probes = 0} to include all features.
#' @param how A character string. The name of the function used to cluster.
#'  Select from "hclust", "kmeans", "agnes", "clara", "diana", "fanny", or
#'  "pam".
#' @param onlyCluster A logical sclar. Toggles whether to return a processed
#'  cluster object or an updated \code{ExprsArray} object.
#' @param ... Additional arguments to the cluster function and/or
#'  other functions used for clustering (e.g., \code{dist} or
#'  \code{cutree}).
#'
#' @return Typically an \code{ExprsArray} object with subject cluster assignments
#'  added to the "cluster" column of the \code{@@anot} slot.
#'
#' @importFrom stats hclust kmeans
#' @importFrom cluster agnes clara diana fanny pam
#'
#' @export
setMethod("modCluster", "ExprsArray",
          function(object, probes, how, onlyCluster = FALSE, ...){

            args <- as.list(substitute(list(...)))[-1]

            # Convert 'numeric' probe argument to 'character' probe vector
            if(class(probes) == "numeric"){

              if(probes == 0) probes <- nrow(object@exprs)
              probes <- rownames(object@exprs[1:probes, ])
              data <- t(object@exprs[probes, ])
            }

            # Build data using supplied 'character' probe vector
            if(class(probes) == "character"){

              data <- t(object@exprs[probes, ])
            }

            # Set the argument 'k' aside to use in 'cutree'
            # NOTE: hclust, agnes, and diana use 'k' via 'cutree'
            if(how %in% c("hclust", "agnes", "diana")){

              if(!"k" %in% names(args)){

                cat("Setting 'k' to '2' (default behavior, override explicitly)...\n")
                args <- append(args, list("k" = 2))
              }

              # Store 'k' outside of 'args' list, then remove 'k' argument
              args.k <- args$k
              args <- args[!"k" %in% names(args)]

              if(how == "hclust"){

                # Add 'metric' to args if not already included (i.e., for dist())
                if(!"metric" %in% names(args)){

                  cat("Setting 'metric' to 'euclidean' (default behavior, override explicitly)...\n")
                  args <- append(args, list("metric" = "euclidean"))
                }

                # Add 'p' to args if not already included (i.e., for dist())
                if(!"p" %in% names(args)){

                  cat("Setting 'p' to '2' (default behavior, override explicitly)...\n")
                  args <- append(args, list("p" = 2))
                }

                # Build distance matrix, then remove dist() args
                cat("Calculating dissimilarity matrix using 'metric' and 'p' arguments...")
                d <- dist(data, method = args$metric, p = args$p)
                args <- args[!"metric" == names(args)]
                args <- args[!"p" == names(args)]

                args <- append(args, list("d" = d))
                result <- do.call(how, args)

              }else{

                args <- append(args, list("x" = data))
                result <- do.call(how, args)
              }

            }else if(how == "kmeans"){

              # Add 'centers' to args (instead of 'k')
              if(!"centers" %in% names(args)){

                cat("Setting 'centers' to '2' (default behavior, override explicitly)...\n")
                args <- append(args, list("centers" = 2))
              }

              args <- append(args, list("x" = data))
              result <- do.call(how, args)

            }else if(how %in% c("clara", "fanny", "pam")){

              # Add 'k' to args if not already included
              if(!"k" %in% names(args)){

                cat("Setting 'k' to '2' (default behavior, override explicitly)...\n")
                args <- append(args, list("k" = 2))
              }

              # clara: cluster large applications
              # fanny: fuzzy analysis
              args <- append(args, list("x" = data))
              result <- do.call(how, args)

            }else{

              stop("Provided how not recognized. Select from 'hclust', 'kmeans', 'agnes', 'clara', 'diana', 'fanny', or 'pam'.\n")
            }

            if(onlyCluster){

              cat("Returning the processed cluster object...\n")
              return(result)

            }else{

              if(how %in% c("hclust", "agnes", "diana")){

                clusts <- cutree(result, k = args.k)
              }

              if(how == "kmeans"){

                clusts <- result$cluster
              }

              if(how %in% c("clara", "fanny", "pam")){

                clusts <- result$clustering
              }

              cat("Updating ExprsArray object...\n")
              object@annot[, "cluster"] <- clusts
              return(object)
            }
          }
)