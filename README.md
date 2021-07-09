
## Testing

aws lambda invoke --function-name Terraformation --invocation-type RequestResponse --payload '{}' --log-type Tail test_response.json && cat test_response.json
