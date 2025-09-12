import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

comprehend = boto3.client('comprehend')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('SentimentAnalysis')

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        text = body.get("text", "")
        
        if not text:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Text is required"})
            }
        
        # Call Comprehend
        response = comprehend.detect_sentiment(
            Text=text,
            LanguageCode="en"
        )
        
        # Convert sentiment scores to Decimal
        score_decimal = {k: Decimal(str(v)) for k, v in response['SentimentScore'].items()}
        
        # Store in DynamoDB
        table.put_item(
            Item={
                'id': str(uuid.uuid4()),
                'text': text,
                'sentiment': response['Sentiment'],
                'sentiment_score': score_decimal,
                'timestamp': datetime.utcnow().isoformat()
            }
        )
        
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            "body": json.dumps(response)
        }
        
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }