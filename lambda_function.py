# lambda_function.py
def lambda_handler(event, context):
    """
    AWS Lambda handler function that returns a simple HTTP response.
    
    Args:
        event (dict): Lambda event data
        context (object): Lambda context object
    
    Returns:
        dict: Response with status code and body
    """
    # Simple logic: return a greeting
    message = 'Hello!'
    if 'name' in event:
        message = f'Hello, {event["name"]}!'
    
    return {
        'statusCode': 200,
        'body': message
    }
