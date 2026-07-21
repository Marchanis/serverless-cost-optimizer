import boto3
import os
from datetime import datetime, timedelta, timezone


def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': ['stopped']
            }
        ]
    )
    
    idle_instances = []
    
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            launch_time = instance['LaunchTime']
            state_reason = instance.get('StateTransitionReason', '')
            
            if '(' in state_reason and ')' in state_reason:
                date_str = state_reason.split('(')[1].split(')')[0]
                date_str = date_str.replace(' GMT', '')
                stopped_date = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')
                stopped_date = stopped_date.replace(tzinfo=timezone.utc)
                
                days_stopped = (datetime.now(timezone.utc) - stopped_date).days
                
                if days_stopped >= 30:
                    idle_instances.append({
                        'InstanceId': instance_id,
                        'LaunchTime': launch_time.isoformat(),
                        'DaysStopped': days_stopped,
                        'StateTransitionReason': state_reason
                    })
                    
    addresses = ec2.describe_addresses()
    
    unused_addresses = []
    
    for address in addresses['Addresses']:
        if 'InstanceId' not in address:
            unused_addresses.append({
                'PublicIp': address['PublicIp'],
                'AllocationId': address.get('AllocationId', ''),
                'AssociationId': address.get('AssociationId', ''),
                'Domain': address.get('Domain', '')
            })
                    
    
    volumes = ec2.describe_volumes()
    
    unused_volumes = []
    
    for volume in volumes['Volumes']:
        if volume['State'] == 'available':
            unused_volumes.append({
                'VolumeId': volume['VolumeId'],
                'Size': volume['Size'],
                'AvailabilityZone': volume['AvailabilityZone'],
                'CreateTime': volume['CreateTime'].isoformat(),
                'state': volume['State']
            })
            
    
    ce = boto3.client('ce')
    today = datetime.now(timezone.utc)
    thirty_days_ago = today - timedelta(days=30)
    
    start_date = thirty_days_ago.strftime('%Y-%m-%d')
    end_date = today.strftime('%Y-%m-%d')
    
    cost_response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': start_date,
            'End': end_date
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        Filter={
            'Dimensions': {
                'Key': 'SERVICE',
                'Values': ['Amazon Elastic Compute Cloud - Compute']
            }
        }
    )
    
    total_cost = float(cost_response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])
    total_cost = round(total_cost, 2)
    
    result = {
        'IdleInstances': idle_instances,
        'UnusedVolumes': unused_volumes,
        'UnusedAddresses': unused_addresses,
        'TotalEC2CostLast30Days': total_cost
    }
    
    sns = boto3.client('sns')
    
    message = str(result)
    
    sns.publish(
        TopicArn = os.environ['SNS_TOPIC_ARN'],
        Message=message,
        Subject='Serverless Cost Optimizer Report'
    )
    
    
    print(result)
    return result