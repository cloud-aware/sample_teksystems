# test_lambda.py
from lambda_function import lambda_handler  # Adjust the import based on your file name

def test_lambda_handler():
    # Define a sample event and context
    event = {}
    context = {}

    # Call the Lambda handler and check the response
    result = lambda_handler(event, context)
    
    # Assert the expected output
    assert result['statusCode'] == 200, "Status code should be 200"
    assert result['body'] == 'Hello!', "Body should be 'Hello!'"
