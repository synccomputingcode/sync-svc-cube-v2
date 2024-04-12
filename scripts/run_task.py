import boto3
import click


@click.command()
@click.option("--task-definition", required=True, help="Name of the task definition")
@click.option("--command", required=True, help="Command to override in the task")
@click.option("--cluster", required=True, help="Name of the ECS cluster")
def run_task(task_definition, command, cluster):
    ecs_client = boto3.client("ecs")
    response = ecs_client.run_task(
        cluster=cluster,
        taskDefinition=task_definition,
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": ["subnet-0d312fb2adaf1b85f"],
                "securityGroups": [
                    "sg-0411c5d85b23bf4ff",
                ],
                "assignPublicIp": "ENABLED",
            }
        },
        overrides={
            "containerOverrides": [{"name": "backend-api", "command": command.split()}]
        },
    )
    task_arn = response["tasks"][0]["taskArn"]
    wait_on_task_stop(cluster, task_arn)
    click.echo("Task stopped")
    task_detail = fetch_task_detail(cluster=cluster, task_arn=task_arn)
    targetContainer = next(
        c for c in task_detail["containers"] if c["name"] == "backend-api"
    )
    if task_detail["stopCode"] != "EssentialContainerExited":
        raise click.ClickException(f"Task Stopped {task_detail['stoppedReason']}")

    if targetContainer.get("exitCode"):
        if targetContainer["exitCode"] != 0:
            raise click.ClickException(
                f"Container exited with exit code {targetContainer['exitCode']}"
            )
    if targetContainer.get("reason"):
        raise click.ClickException(f"Container stopped {targetContainer['reason']}")
    click.echo("Task completed")


def wait_on_task_stop(cluster: str, task_arn: str):
    task_detail = fetch_task_detail(cluster, task_arn=task_arn)
    notified_status = ""
    while task_detail.get("lastStatus") != "STOPPED":
        if task_detail.get("lastStatus") != notified_status:
            click.echo(
                f"[Task Status Changed] : {task_detail.get('notifiedStatus')}"
                f" - {task_detail['lastStatus']}"
            )
            notified_status = task_detail["lastStatus"]
        task_detail = fetch_task_detail(cluster, task_detail["taskArn"])


def fetch_task_detail(cluster: str, task_arn: str):
    client = boto3.client("ecs")
    tasks = client.describe_tasks(cluster=cluster, tasks=[task_arn]).get("tasks")
    return tasks[0]


if __name__ == "__main__":
    run_task()
