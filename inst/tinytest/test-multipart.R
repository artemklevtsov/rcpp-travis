# Test parse_multipart

source("setup.R")

# import functions
parse_multipart_boundary = rcpptravis:::parse_multipart_boundary
parse_multipart_body = rcpptravis:::parse_multipart_body

# Test parse_multipart_boundary with empty object
expect_error(parse_multipart_boundary(NULL))
expect_error(parse_multipart_boundary(NA))
expect_error(parse_multipart_boundary(NA_character_))
expect_error(parse_multipart_boundary(""))

# Test parse_multipart_boundary
boundary = "------------------------e529c2e8d1153bc8"
ctype = paste0("multipart/form-data; boundary=", boundary)
expect_equal(parse_multipart_boundary(ctype), boundary)

# Test parse_multipart_body with empty object
expect_error(parse_multipart_body(NULL, NULL))
expect_error(parse_multipart_body(NA_character_, NA_character_))
expect_error(parse_multipart_body("", ""))
expect_equal(parse_multipart_body(raw(), character(1)), list())

# Test parse_multipart_body
# text file
tmp_txt = system.file("DESCRIPTION", package = "rcpptravis")
# rds file
tmp_rds = tempfile(fileext = ".rds")
saveRDS(letters, tmp_rds)
# form values
params = list(
  "param1" = "value1",
  "param2" = "value2"
)
# form files
files = list(
  "desc_file.txt" = list(
    path = tmp_txt,
    ctype = "plain/text"
  ),
  "raw_file.bin" = list(
    path = tmp_rds,
    ctype = "application/octet-stream"
  )
)

body = make_multipart_body(params, files)
boundary = parse_multipart_boundary(attr(body, "content-type"))
parsed = parse_multipart_body(body, paste0("--", boundary))

expect_true(inherits(parsed, "list"))
expect_equal(names(parsed), c("files", "values"))
expect_true(inherits(parsed$values, "list"))
expect_equal(length(parsed$values), 2L)
expect_equal(parsed$values$param1, "value1")
expect_equal(parsed$values$param2, "value2")
expect_true(inherits(parsed$files, "list"))
expect_equal(length(parsed$files), 2L)

# Test text file
expect_equal(parsed$files[["desc_file.txt"]]$filename, basename(tmp_txt))
expect_equal(parsed$files[["desc_file.txt"]]$content_type, "plain/text")
expect_equal(parsed$files[["desc_file.txt"]]$length, file.size(tmp_txt))
expect_identical(get_multipart_file(body, parsed$files[["desc_file.txt"]]),
                 readBin(tmp_txt, raw(), file.size(tmp_txt)))

# Test binary file
expect_equal(parsed$files[["raw_file.bin"]]$filename, basename(tmp_rds))
expect_equal(parsed$files[["raw_file.bin"]]$content_type, "application/octet-stream")
expect_equal(parsed$files[["raw_file.bin"]]$length, file.size(tmp_rds))
expect_identical(get_multipart_file(body, parsed$files[["raw_file.bin"]]),
                 readBin(tmp_rds, raw(), file.size(tmp_rds)))
