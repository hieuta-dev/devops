# compiler
tofu fmt -check -recursive
tofu init -backend=false
tofu validate

# static analysis
tflint --init
tflint --recursive


# integration test

tofu init
tofu test