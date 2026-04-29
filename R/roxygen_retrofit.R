#' Retrofit a package using its roxygen / Rd documentation
#'
#' @description
#' Reads installed `.Rd` documentation for `pkgname`, extracts a type
#' spec for every documented `\\arguments` item and `\\value` block,
#' and applies the result via [enable_for_package()].
#'
#' Two extraction layers run in sequence:
#'
#' * **Explicit tag.** A description that begins with `[type]`
#'   (e.g. `@param x [integer] Number of iterations`) is parsed
#'   verbatim. Whatever sits between the brackets becomes the spec
#'   string.
#' * **Vocabulary heuristic.** Otherwise the description's leading
#'   prose is matched against a small vocabulary of common R type
#'   names (`numeric`, `integer`, `character`, `logical`, ...). The
#'   patterns are anchored to the start of the description, so prose
#'   like "A numeric vector" matches but "the function applied to..."
#'   does not. See [default_type_vocabulary()].
#'
#' The resulting `.specs` list is merged with anything you pass in
#' explicitly (your overrides win), filtered to formals that actually
#' exist on each function, then forwarded to [enable_for_package()].
#' That means inference from defaults still runs for arguments the
#' docs do not describe.
#'
#' Use this when an existing package already has decent prose docs
#' but no type information — typethis lifts what is already written.
#' For specs the heuristics cannot recover, add explicit `[type]`
#' tags in your roxygen, or pass them via `.specs`.
#'
#' @param pkgname Package name (string) for an installed package, or
#'   an environment together with `.rd_dir` for testing / source
#'   workflows.
#' @param .specs,.infer,.validate,.coerce,.filter Forwarded to
#'   [enable_for_package()]. Per-function entries in `.specs` win
#'   over Rd-derived specs.
#' @param .vocabulary A named character vector mapping perl-regex
#'   patterns to spec strings. The first matching pattern wins, so
#'   order matters. Defaults to [default_type_vocabulary()].
#' @param .rd_dir Optional path to a directory containing `.Rd`
#'   files. When supplied, files are parsed from disk instead of
#'   via `tools::Rd_db()`. Useful for testing and for source
#'   packages that have not been installed.
#' @return Invisibly, the character vector of names that were
#'   retrofitted.
#' @family typed functions
#' @seealso [enable_for_package()] for the underlying retrofit;
#'   [parse_param_type()] for the per-string extractor;
#'   [default_type_vocabulary()] for the prose-to-spec mapping.
#' @export
#' @examples
#' # Inside R/zzz.R of your package:
#' # .onLoad <- function(libname, pkgname) {
#' #   typethis::as_typed_from_roxygen(pkgname)
#' # }
#'
#' # Demonstration with a synthetic Rd directory:
#' rd_dir <- tempfile("rd")
#' dir.create(rd_dir)
#' writeLines(c(
#'   "\\name{add}",
#'   "\\alias{add}",
#'   "\\title{Add two numbers}",
#'   "\\arguments{",
#'   "\\item{x}{A numeric vector.}",
#'   "\\item{y}{[integer] Number of times.}",
#'   "}",
#'   "\\value{A numeric vector.}"
#' ), file.path(rd_dir, "add.Rd"))
#'
#' ns <- new.env()
#' ns$add <- function(x, y) rep(x, y)
#' as_typed_from_roxygen(ns, .rd_dir = rd_dir)
#' get_signature(ns$add)
as_typed_from_roxygen <- function(
  pkgname,
  .specs = list(),
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE,
  .filter = NULL,
  .vocabulary = default_type_vocabulary(),
  .rd_dir = NULL
) {
  ns <- resolve_namespace(pkgname)
  rd_db <- load_rd_db(pkgname, .rd_dir)

  rd_specs <- list()
  for (rd in rd_db) {
    extracted <- extract_specs_from_rd(rd, .vocabulary)
    if (is.null(extracted)) {
      next
    }
    for (alias in extracted$aliases) {
      if (is.null(rd_specs[[alias]])) {
        rd_specs[[alias]] <- extracted$spec
      } else {
        rd_specs[[alias]] <- utils::modifyList(
          rd_specs[[alias]],
          extracted$spec,
          keep.null = FALSE
        )
      }
    }
  }

  cleaned <- prune_specs_to_namespace(rd_specs, ns)

  merged <- cleaned
  for (nm in names(.specs)) {
    if (is.null(merged[[nm]])) {
      merged[[nm]] <- .specs[[nm]]
    } else {
      merged[[nm]] <- utils::modifyList(
        merged[[nm]],
        .specs[[nm]],
        keep.null = TRUE
      )
    }
  }

  enable_for_package(
    ns,
    .specs = merged,
    .infer = .infer,
    .validate = .validate,
    .coerce = .coerce,
    .filter = .filter
  )
}

#' Default prose-to-spec vocabulary for [as_typed_from_roxygen()]
#'
#' @description
#' A named character vector. Names are perl-flavoured regex patterns;
#' values are spec strings forwarded to [as_typed()]. Patterns are
#' anchored to the start of an argument's prose description, with
#' optional leading articles (`a`, `an`, `the`, `single`, `optional`,
#' ...). The first match wins.
#'
#' Extend by combining with your own entries:
#'
#' ```r
#' my_vocab <- c(
#'   "^\\s*(?:a|an)?\\s*tbl[._]df\\b" = "data.frame",
#'   default_type_vocabulary()
#' )
#' as_typed_from_roxygen("mypkg", .vocabulary = my_vocab)
#' ```
#'
#' @return A named character vector.
#' @family typed functions
#' @seealso [as_typed_from_roxygen()] for the consumer;
#'   [parse_param_type()] for the per-string extractor.
#' @export
default_type_vocabulary <- function() {
  prefix <- "(?i)^\\s*(?:a|an|the|single|optional|named|positive|non-negative)?\\s*"
  c(
    setNames("data.frame", paste0(prefix, "data[.\\s]frame\\b")),
    setNames(
      "character",
      paste0(
        prefix,
        "(?:character\\s+string|character\\s+vector|character\\s+scalar|string|character)\\b"
      )
    ),
    setNames(
      "integer",
      paste0(prefix, "(?:integer\\s+vector|integer)\\b")
    ),
    setNames(
      "numeric",
      paste0(
        prefix,
        "(?:numeric\\s+vector|numeric\\s+scalar|numeric|number|count)\\b"
      )
    ),
    setNames("double", paste0(prefix, "double\\b")),
    setNames(
      "logical",
      paste0(
        prefix,
        "(?:logical\\s+vector|logical\\s+scalar|logical|boolean)\\b"
      )
    ),
    setNames(
      "logical",
      "(?i)^\\s*(?:either\\s+)?(?:true\\s+or\\s+false|`?true`?\\s+or\\s+`?false`?)\\b"
    ),
    setNames("logical", "(?i)^\\s*if\\s+(?:true|false)\\b"),
    setNames("list", paste0(prefix, "list\\b")),
    setNames("environment", paste0(prefix, "environment\\b")),
    setNames("function", paste0(prefix, "function\\b"))
  )
}

#' Map a single prose description to a type spec
#'
#' @description
#' The per-string extractor used by [as_typed_from_roxygen()]. Tries
#' an explicit `[type]` prefix first, then falls back to the
#' supplied vocabulary. Returns `NULL` when nothing matches.
#'
#' @param desc A character string — typically the prose body of a
#'   `@param` tag (or the contents of a `\\value{}` block).
#' @param vocabulary A named character vector as returned by
#'   [default_type_vocabulary()].
#' @return A spec string, or `NULL` if no rule matched.
#' @family typed functions
#' @seealso [default_type_vocabulary()] for the default rules.
#' @export
#' @examples
#' parse_param_type("[integer] number of iterations")
#' parse_param_type("A numeric vector of values")
#' parse_param_type("If TRUE, return early")
#' parse_param_type("Some unrelated description")
parse_param_type <- function(desc, vocabulary = default_type_vocabulary()) {
  if (!is.character(desc) || length(desc) != 1L || is.na(desc)) {
    return(NULL)
  }
  if (!nzchar(trimws(desc))) {
    return(NULL)
  }

  explicit <- regmatches(
    desc,
    regexpr("^\\s*\\[\\s*([^\\]]+?)\\s*\\]", desc, perl = TRUE)
  )
  if (length(explicit) > 0L && nzchar(explicit)) {
    inside <- sub("^\\s*\\[\\s*([^\\]]+?)\\s*\\].*", "\\1", explicit, perl = TRUE)
    if (nzchar(inside)) {
      return(inside)
    }
  }

  head <- substring(desc, 1L, 120L)
  for (i in seq_along(vocabulary)) {
    if (grepl(names(vocabulary)[i], head, perl = TRUE)) {
      return(unname(vocabulary[i]))
    }
  }
  NULL
}

# ----- Rd-tree helpers (internal) -----

# Lazily lookup `Rd_tag` so non-Rd nodes get an empty string.
rd_tag_of <- function(x) {
  t <- attr(x, "Rd_tag")
  if (is.null(t)) "" else t
}

# Recursively flatten an Rd subtree to plain text. Strips macro
# decoration but keeps the prose verbatim — suitable for heuristic
# matching, not for rendering.
rd_flatten <- function(x) {
  if (is.character(x)) {
    return(paste(x, collapse = ""))
  }
  if (is.list(x)) {
    return(paste(vapply(x, rd_flatten, character(1)), collapse = ""))
  }
  ""
}

# Pull every alias name from an Rd tree. Aliases include the primary
# `\name{}` plus all `\alias{}` entries.
extract_aliases <- function(rd) {
  tags <- vapply(rd, rd_tag_of, character(1))
  keep <- tags %in% c("\\name", "\\alias")
  if (!any(keep)) {
    return(character(0))
  }
  unique(trimws(vapply(rd[keep], rd_flatten, character(1))))
}

# Pull (name, description) pairs from `\arguments{ \item{name}{desc} }`.
# Names like `x,y` produce one entry per name with a shared description.
# `...` and empty names are dropped.
extract_arguments <- function(rd) {
  tags <- vapply(rd, rd_tag_of, character(1))
  args_idx <- which(tags == "\\arguments")
  if (length(args_idx) == 0L) {
    return(list())
  }
  args_block <- rd[[args_idx[1]]]
  inner_tags <- vapply(args_block, rd_tag_of, character(1))
  items <- args_block[inner_tags == "\\item"]
  out <- list()
  for (item in items) {
    if (length(item) < 2L) {
      next
    }
    raw_name <- trimws(rd_flatten(item[[1]]))
    desc <- rd_flatten(item[[2]])
    parts <- trimws(strsplit(raw_name, ",", fixed = TRUE)[[1]])
    for (nm in parts) {
      if (!nzchar(nm) || nm == "...") {
        next
      }
      out[[nm]] <- desc
    }
  }
  out
}

# Pull the `\value{}` prose if any; returns "" when absent.
extract_value <- function(rd) {
  tags <- vapply(rd, rd_tag_of, character(1))
  idx <- which(tags == "\\value")
  if (length(idx) == 0L) {
    return("")
  }
  rd_flatten(rd[[idx[1]]])
}

# Build a per-Rd-block specs payload: { aliases, spec = list(arg = ..., .return = ...) }.
# Returns NULL when nothing usable was extracted.
extract_specs_from_rd <- function(rd, vocabulary = default_type_vocabulary()) {
  aliases <- extract_aliases(rd)
  if (length(aliases) == 0L) {
    return(NULL)
  }
  args <- extract_arguments(rd)
  spec <- list()
  for (nm in names(args)) {
    parsed <- parse_param_type(args[[nm]], vocabulary)
    if (!is.null(parsed)) {
      spec[[nm]] <- parsed
    }
  }
  value_text <- extract_value(rd)
  if (nzchar(trimws(value_text))) {
    parsed_return <- parse_param_type(value_text, vocabulary)
    if (!is.null(parsed_return)) {
      spec[[".return"]] <- parsed_return
    }
  }
  if (length(spec) == 0L) {
    return(NULL)
  }
  list(aliases = aliases, spec = spec)
}

# Resolve `pkgname` to an environment. Accepts an environment directly
# or a non-empty single string (looked up via `asNamespace`).
resolve_namespace <- function(pkgname) {
  if (is.environment(pkgname)) {
    return(pkgname)
  }
  if (
    is.character(pkgname) &&
      length(pkgname) == 1L &&
      !is.na(pkgname) &&
      nzchar(pkgname)
  ) {
    return(asNamespace(pkgname))
  }
  stop("pkgname must be a single non-empty string (or an environment)")
}

# Load Rd entries either from a directory of `.Rd` files (when
# `rd_dir` is supplied) or via `tools::Rd_db()` for an installed
# package. Returns a list of parsed Rd trees.
load_rd_db <- function(pkgname, rd_dir) {
  if (!is.null(rd_dir)) {
    if (!is.character(rd_dir) || length(rd_dir) != 1L || !dir.exists(rd_dir)) {
      stop(".rd_dir must be an existing directory path")
    }
    files <- list.files(rd_dir, pattern = "\\.Rd$", full.names = TRUE)
    db <- lapply(files, tools::parse_Rd)
    names(db) <- basename(files)
    return(db)
  }
  if (!is.character(pkgname) || length(pkgname) != 1L) {
    stop(
      "pkgname must be a single string when .rd_dir is not given",
      call. = FALSE
    )
  }
  tools::Rd_db(pkgname)
}

# Drop spec entries whose key is not a real, non-primitive function
# in `ns`, and whose argument names do not match the function's
# formals (plus the `.return` meta-key). Empty resulting entries
# are dropped entirely so `enable_for_package()` does not have to
# carry noise.
prune_specs_to_namespace <- function(rd_specs, ns) {
  candidates <- ls(envir = ns, all.names = TRUE)
  out <- list()
  for (nm in names(rd_specs)) {
    if (!(nm %in% candidates)) {
      next
    }
    fn <- get(nm, envir = ns, inherits = FALSE)
    if (!is.function(fn) || is.primitive(fn)) {
      next
    }
    formal_names <- names(formals(fn))
    spec <- rd_specs[[nm]]
    keep <- names(spec) %in% c(formal_names, ".return")
    spec <- spec[keep]
    if (length(spec) > 0L) {
      out[[nm]] <- spec
    }
  }
  out
}
