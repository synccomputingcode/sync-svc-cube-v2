import boto3
import click


@click.command()
@click.option("--task-definition", required=True, help="Name of the task definition")
@click.option("--container-name", required=True, help="Name of the container to update")
@click.option("--image", required=True, help="New image URI")
def update_task_definition(task_definition, container_name, image):
    ecs = boto3.client("ecs")

    # Retrieve the current task definition
    response = ecs.describe_task_definition(taskDefinition=task_definition)
    current_task_def = response["taskDefinition"]

    # Create a new task definition with the updated image
    new_task_def = {**current_task_def, "containerDefinitions": []}

    # Update the image for the specified container
    for container_def in current_task_def["containerDefinitions"]:
        if container_def["name"] == container_name:
            container_def["image"] = image
        new_task_def["containerDefinitions"].append(container_def)
    new_task_def.pop("taskDefinitionArn")
    new_task_def.pop("revision")
    new_task_def.pop("status")
    new_task_def.pop("requiresAttributes")
    new_task_def.pop("compatibilities")
    new_task_def.pop("registeredAt")
    new_task_def.pop("registeredBy")

    # Register the new task definition
    response = ecs.register_task_definition(**new_task_def)
    new_task_def_arn = response["taskDefinition"]["taskDefinitionArn"]

    click.echo(
        "Task definition updated successfully."
        f" New task definition ARN: {new_task_def_arn}"
    )


if __name__ == "__main__":
    update_task_definition()
