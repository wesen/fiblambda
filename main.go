package main

import (
	"errors"
	"github.com/aws/aws-lambda-go/lambda"
)

func fibonacci(i int) int {
	if i < 0 {
		return -1
	} else if i == 0 {
		return 0
	} else if i <= 2 {
		return 1
	} else {
		return fibonacci(i-2) + fibonacci(i-1)
	}
}

func handler(n int) (int, error) {
	if n < 0 {
		return -1, errors.New("Input must be a positive number")
	}
	return fibonacci(n), nil
}

func main() {
	lambda.Start(handler)
}
