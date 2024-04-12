import mimetypes
import sys
import time
from pathlib import Path

import boto3
import click


def get_ssm_parameter(name):
    # get ssm parameter
    client = boto3.client("ssm", region_name="us-east-1")
    response = client.get_parameter(Name=name)
    return response["Parameter"]["Value"]


def upload_directory_to_s3(bucket: str, path: Path, subdir: Path = Path(".")):
    s3 = boto3.client("s3")
    for file in path.rglob("*"):
        if file.is_file():
            # detect content type

            content_type = mimetypes.guess_type(str(file))[0]
            if content_type is None:
                content_type = "application/octet-stream"
            s3.upload_file(
                Filename=str(file),
                Bucket=bucket,
                Key=str(subdir / file.relative_to(path)),
                ExtraArgs={"ContentType": content_type},
            )
            click.echo(f"Uploaded {file} to s3://{bucket}")


def create_cloudfront_invalidation(distribution_id: str):
    client = boto3.client("cloudfront")
    client.create_invalidation(
        DistributionId=distribution_id,
        InvalidationBatch={
            "Paths": {"Quantity": 1, "Items": ["/*"]},
            "CallerReference": time.strftime("%Y%m%d%H%M%S"),
        },
    )
    click.echo(f"Created CloudFront invalidation for {distribution_id}")


@click.command()
def deploy_frontend():
    click.echo("Deploying frontend")
    # check frontend is built
    for path in [Path("frontend/dist"), Path("backend/staticfiles")]:
        if not path.exists():
            click.echo(
                f"{path} is not built."
                " Run `pixi run frontend-build` "
                "or `pixi run backend-collect-statics`"
            )
            sys.exit(1)
        target_bucket = get_ssm_parameter("/resume/s3/bucket")
        # upload to s3
        upload_directory_to_s3(target_bucket, path)
    # reset cloudfront distribution
    cloudfront_distribution_id = get_ssm_parameter("/resume/cdn/distribution_id")
    create_cloudfront_invalidation(cloudfront_distribution_id)
    click.echo("Deployment complete")


if __name__ == "__main__":
    deploy_frontend.main()
