import os
import uuid
import boto3
from botocore.exceptions import BotoCoreError, NoCredentialsError, ClientError

AWS_BUCKET = os.getenv("AWS_S3_BUCKET")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")


def _client():
    return boto3.client(
        "s3",
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=AWS_REGION,
    )


def create_presigned_put_url(file_name: str, content_type: str):
    """Generate a short-lived presigned PUT URL and the resulting public object URL."""
    if not AWS_BUCKET:
        raise ValueError("AWS_S3_BUCKET is not configured")

    key = f"recipes/{uuid.uuid4()}-{file_name}"

    try:
        client = _client()
        upload_url = client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": AWS_BUCKET,
                "Key": key,
                "ContentType": content_type,
            },
            ExpiresIn=600,
        )
    except (BotoCoreError, NoCredentialsError, ClientError) as e:
        raise RuntimeError(f"Error generating presigned URL: {e}") from e

    # Generate public read URL (bucket must have public read policy or generate presigned GET URL later)
    file_url = f"https://{AWS_BUCKET}.s3.amazonaws.com/{key}"
    return key, upload_url, file_url


def create_presigned_get_url(file_url: str, expires_in: int = 86400):
    """Generate a presigned GET URL for reading an object from S3.
    
    Args:
        file_url: The full S3 URL (e.g., https://bucket.s3.amazonaws.com/key)
        expires_in: Time in seconds until the URL expires (default 24 hours)
    
    Returns:
        A presigned URL string that allows temporary read access
    """
    if not AWS_BUCKET:
        raise ValueError("AWS_S3_BUCKET is not configured")
    
    # Extract the key from the full URL
    # Example: https://ayerecipesimagesbucket.s3.amazonaws.com/recipes/abc.jpg -> recipes/abc.jpg
    try:
        key = file_url.split(f"{AWS_BUCKET}.s3.amazonaws.com/")[1]
    except IndexError:
        # If URL format is different, try alternative format
        try:
            key = file_url.split(f"s3.amazonaws.com/{AWS_BUCKET}/")[1]
        except IndexError:
            # If still fails, assume it's already just a key
            key = file_url
    
    try:
        client = _client()
        presigned_url = client.generate_presigned_url(
            "get_object",
            Params={
                "Bucket": AWS_BUCKET,
                "Key": key,
            },
            ExpiresIn=expires_in,
        )
        return presigned_url
    except (BotoCoreError, NoCredentialsError, ClientError) as e:
        raise RuntimeError(f"Error generating presigned GET URL: {e}") from e


def delete_image_from_s3(file_url: str):
    """Delete an image from S3 bucket.
    
    Args:
        file_url: The full S3 URL (e.g., https://bucket.s3.amazonaws.com/key)
    
    Returns:
        True if deletion was successful, False otherwise
    """
    if not AWS_BUCKET or not file_url:
        return False
    
    try:
        # Extract the key from the full URL
        try:
            key = file_url.split(f"{AWS_BUCKET}.s3.amazonaws.com/")[1]
        except IndexError:
            # If URL format is different, try alternative format
            try:
                key = file_url.split(f"s3.amazonaws.com/{AWS_BUCKET}/")[1]
            except IndexError:
                # If still fails, assume it's already just a key
                key = file_url
        
        client = _client()
        client.delete_object(Bucket=AWS_BUCKET, Key=key)
        print(f"Successfully deleted S3 object: {key}")
        return True
    except (BotoCoreError, NoCredentialsError, ClientError) as e:
        print(f"Error deleting S3 object: {e}")
        return False
