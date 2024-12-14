# should send the following line
assign <- x

# all 3 following lines should sent
pipe <- x |>
  sort() |>
  unique()

# if on the function assignment, should send function definition
# long multiline comment
f <- function(a, b, c) {
  a <- a + b # if execute from here, should send this line
  b + c
}

for (i in 1:10) { # send entire loop
  print(i) # send this line
}

if (TRUE) { # send entire if statement
  print("TRUE") # send single line

  print("FALSE")
} else { # send entire if statement
  print("FALSE") # send single line
}

if (TRUE) {
  x <- x |>
    # how do comments work?
    sort() |>
    unique()
}

f1 <- function() {
  x <- 2
  f2 <- function() {
    1
  }
  f2() + x
}

# Test empty function
empty_func <- function() { }

# Test empty loop
for (i in seq_len(0)) { }

# styler: off
if (TRUE)
  print("TRUE")

# styler: on

if (true) x else y
