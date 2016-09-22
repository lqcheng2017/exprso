## exprso 0.1.5.9000
---------------------
* 1.2-methods.R
  * Rename `getProbeSet` to `getFeatures`.
* 2.1-import.R
  * Rename `probes.begin` argument to `begin`.
* 4.1-modSwap.R
  * Have `fsPrcomp` use `top` argument.
* 4.2-modCluster.R
  * Change `probes` argument to `top`.
* 5.1-fs-binary.R
  * Change `probes` argument to `top`.
* 5.2-build-binary.R
  * Change `probes` argument to `top`.
* 5.3-doMulti.R
  * Change `probes` argument to `top`.
* 7.1-plCV.R
  * Change `probes` argument to `top`.
* 7.2-plGrid.R
  * Change `probes` argument to `top`.
* 7.3-plMonteCarlo.R
  * Change `probes` argument to `top`.
* 8.1-pipe.R
  * Change `top.N` argument to `top`.
* 8.2-ens.R
  * Change `top.N` argument to `top`.

## exprso 0.1.5
---------------------
* 1.1-classes.R
  * Add `actual` slot to `ExprsPredict` object.
* 1.2-methods.R
  * Add 2D plotting to `plot` method.
* 2.1-import.R
  * Force `stringsAsFactors = FALSE`.
* 4.1-modSwap.R
  * Clean up plot calls using new `plot` method.
* 6-predict.R
  * Add class check for `modHistory` `@reductionModel`.
  * Add class check for `predict` `@mach`.
  * Pass along known class values to `ExprsPredict` result.
  * Remove `calcStats` `array` argument.
* 7.1-plCV.R
  * Tidy `calcStats` calls.
* 7.2-plGrid.R
  * Tidy `calcStats` calls.
* 8.2-ens.R
  * Pass along known class values to `ExprsPredict` result.
* 9-global.R
  * Find optimal import combination.
* 9-tidy.R
  * Add `pipeSubset` function.

## exprso 0.1.4
---------------------
* 2.1-import.R
  * Deprecated `arrayRead` and `arrayEset` functions.
  * New `arrayExprs` function adds `data.frame` support.
* 3.1-split.R
  * Remove `splitSample` warning.
  * Add details to the "Please Read" vignette.
* 4.2-cluster.R
  * Add support for numeric vector probes.
* 4.3-compare.R
  * Convert `compare` warning into error.
* 5.1-fs-binary.R
  * Add imports to NAMESPACE.
  * Add `fs.` method to wrap repetitive code.
  * Add support for numeric vector probes.
  * Remove the `fsStats` "ks-boot" method.
  * Remove `fsPenalizedSVM`.
* 5.2-build-binary.R
  * Add imports to NAMESPACE.
  * Add `build.` method to wrap repetitive code.
  * Add support for numeric vector probes.
* 7.1-plCV.R
  * Remove `plCV` warning.
  * Add details to the "Please Read" vignette.
* 7.2-plGrid.R
  * Convert `plGrid` warning into a message.
  * Consolidate numeric probes handling.
  * Add handling for a list of numeric or character probes.
  * Add details to the "Please Read" vignette.
* 8.1-pipe.R
  * Convert `pipeFilter` warning into a message.
  * Add details to the "Please Read" vignette.
* 9-deprecated.R
  * Contains deprecated functions.
* 9-tidy.R
  * Add `getArgs`, `defaultArg`, and `forceArg` functions.
  * Add `trainingSet`, `validationSet`, and `testSet` functions.
  * Add `modSubset` wrapper for `subset` method.

## exprso 0.1.3
---------------------
* 1.1-classes.R
  * Fixed warnings and notes.
* 1.2-methods.R
  * Fixed warnings and notes.
* 2.1-import.R
  * Fixed warnings and notes.
* 2.2-misc.R
  * Code renamed to file 2.2-process.R.
  * Fixed warnings and notes.
* 3.1-split.R
  * Fixed warnings and notes.
* 4.1-modSwap.R
  * Store mutated annotation as boolean (not factor).
  * Fixed warnings and notes.
* 4.2-modCluster.R
  * Fixed warnings and notes.
* 4.3-compare.R
  * Fixed warnings and notes.
* 5.1-fs-binary.R
  * Fixed warnings and notes.
* 5.2-build-binary.R
  * Fixed warnings and notes.
* 5.3-doMulti.R
  * Fixed warnings and notes.
* 6-predict.R
  * Fixed warnings and notes.
* 8.1-pipe.R
  * Fixed warnings and notes.
* 8.2-ens.R
  * Fixed warnings and notes.
* 9-global.R
  * Contains global imports.

## exprso 0.1.2
---------------------
* 1.2-methods.R
  * Added `subset` method for `ExprsArray` objects.
  * Added `subset` method for `ExprsPipeline` objects.
* 3-split.R
  * Code renamed to file 3.1-split.R.
* 4-conjoin.R
  * Code renamed to file 3.2-conjoin.R.
  * `modMutate` merged with `modSwap` as 4.1-modSwap.R.
  * `modCluster` method added as 4.2-modCluster.R.
  * `compare` method added as 4.3-compare.R.
  * `compare` now handles `ExprsMulti` objects.
  * `compare` test added to validate method.
* 5.1-fs-binary.R
  * `fsStats` has tryCatch to address rare error.

## exprso 1.0.1
---------------------
* 1.2-methods.R
  * `summary` method now accommodates lists of vector arguments.
* 5.2-build-binary.R
  * Added `buildDNN.ExprsBinary` method.
  * Removed `e1071` cross-validation.
* 5.3-doMulti.R
  * Added `buildDNN.ExprsMulti` method.
* 6-build.R
  * Added `buildDNN` predict clause.
* 7.2-plGrid.R
  * `plGrid` method now accommodates lists of vector arguments.
  * Removed `e1071` cross-validation.

## exprso 0.1.0
---------------------
* Project now organized in a package distribution format.
* 0-misc.R
  * Temporarily removed `compare` function.
  * Code renamed to file 2.2-misc.R.
* 1-classes.R
  * Code divided into files 1.1-classes.R and 1.2-methods.R.
  * Remaining 1-classes.R code renamed to 4-conjoin.R.
  * Removed `getCases` and `getConts`. Use `[` and `$` instead.
  * `getProbeSet` extended to replace `getProbeSummary`.
* 2-import.R
  * Code renamed to file 2.1-import.R.
* 3-split.R
  * `arraySubset` replaced with `[` and `$` in 1.1-classes.R.
  * `splitSample` code heavily edited, including an `all.in` bug fix.
  * `splitStratify` now handles `ExprsMulti` objects.
* 4-speakEasy.R
  * Temporarily removed `speakEasy` and `abridge` functions.
* 5-fs.R
  * Code renamed to file 5.1-fs-binary.R.
* 6-build.R
  * `reRank` function serializes `doMulti` fs added to 5.3-doMulti.R.
  * `fsSample` and `fsStats` now have `ExprsMulti` methods.
  * Some code move to 5.2-build-binary.R and 5.3-doMulti.R.
  * Remaining 6-build.R code renamed to 6-predict.R.
* 7-pl.R
  * Code divided into a separate file for each `pl` method.
  * Replaced ctrlGS (ctrlGridSearch) with ctrlPL (ctrlPipeLine).
  * `plCV`, fixed "1-subject artifact"" with `drop = FALSE`.
  * `plNested`, fixed "1-subject artifact" with `drop = FALSE`.
  * `plNested` argument checks moved to separate function.
* 8-ens.R
  * Code divided into files 8.1-pipe.R and 8.2-ens.R.
  * Removed `pipeSubset`. Use `[` and `$` instead.
