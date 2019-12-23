# Scales an ASG up and down again 
# If there is a new version of the launch template that references a different
# AMI then the default termination policy will delete the old versions of the instances
# on scaledown. This allows us to do a hot-swap deployment.

# TODO improve the error handling, parameterise the hardcoded variables

import boto3
from time import sleep



upscale = 4
downscale = 2
asg_name = 'asg_round_robin'

def main():
    client = boto3.client('autoscaling')
    scale_up(client)
    if (wait_for_scaled_nodes(client, upscale) == False ):
        return 1

    scale_down(client)
    if (wait_for_scaled_nodes(client, downscale) == False):
        return 1

    return 0    

def scale_up(client):
    print(f"Scaling up to {upscale} instances")
    response = client.set_desired_capacity(
        AutoScalingGroupName=asg_name,
        DesiredCapacity=upscale,
        HonorCooldown=False
    )    

# Filter function for checking running instances
def instance_is_running(instance):
    if (instance['LifecycleState'] == 'InService'):
        return True
    else:
        return False

def wait_for_scaled_nodes(client, target_number):
    i = 0
    while i < 20:
        sleep(20) 
        response = client.describe_auto_scaling_instances()
        running_instances = list(filter( instance_is_running, response['AutoScalingInstances']))
        print( f"{len(running_instances)} running instances" )
        if len(running_instances) == target_number:
            return True
        i = i + 1    
    print('Instances failed to achieve running state' )
    return False


def scale_down(client):
    print(f"Scaling down to {downscale} instances")
    response = client.set_desired_capacity(
        AutoScalingGroupName=asg_name,
        DesiredCapacity=downscale,
        HonorCooldown=False
    )        

if __name__=="__main__":
    main()    