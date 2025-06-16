import logging
import boto3
import socket
import os

# Initialize clients
elbv2_client = boto3.client('elbv2')
rds_client = boto3.client('rds')

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Load cluster details from environment variables
CLUSTER_NAME = os.environ['CLUSTER_NAME']
CLUSTER_PORT = int(os.environ['CLUSTER_PORT'])
TARGET_GROUP_ARN = os.environ['TARGET_GROUP_ARN']

def get_cluster_instance_ips():
    """Get all IP addresses for instances in the cluster"""
    try:
        # Get cluster details
        cluster_response = rds_client.describe_db_clusters(DBClusterIdentifier=CLUSTER_NAME)
        if not cluster_response['DBClusters']:
            raise Exception(f"No clusters found for {CLUSTER_NAME}")

        cluster = cluster_response['DBClusters'][0]
        cluster_members = cluster.get('DBClusterMembers', [])

        instance_ips = []

        # Get IP for each cluster member
        for member in cluster_members:
            instance_id = member['DBInstanceIdentifier']
            try:
                instance_response = rds_client.describe_db_instances(DBInstanceIdentifier=instance_id)
                instance = instance_response['DBInstances'][0]
                endpoint = instance['Endpoint']['Address']
                ip_address = socket.gethostbyname(endpoint)
                instance_ips.append(ip_address)
                logger.info(f"Found IP {ip_address} for instance {instance_id}")
            except Exception as e:
                logger.error(f"Error getting IP for instance {instance_id}: {e}")

        return instance_ips
    except Exception as e:
        logger.error(f"Error getting cluster instance IPs: {e}")
        raise

def update_target_group():
    try:
        logger.info(f"Updating target group for cluster {CLUSTER_NAME}")

        # Get current instance IPs
        current_ips = get_cluster_instance_ips()

        # Get existing targets in target group
        targets_response = elbv2_client.describe_target_health(TargetGroupArn=TARGET_GROUP_ARN)
        existing_targets = [target['Target']['Id'] for target in targets_response['TargetHealthDescriptions']]

        # Determine which targets to add and remove
        targets_to_add = [ip for ip in current_ips if ip not in existing_targets]
        targets_to_remove = [ip for ip in existing_targets if ip not in current_ips]

        # Remove outdated targets
        if targets_to_remove:
            elbv2_client.deregister_targets(
                TargetGroupArn=TARGET_GROUP_ARN,
                Targets=[{'Id': ip, 'Port': CLUSTER_PORT} for ip in targets_to_remove]
            )
            logger.info(f"Removed targets: {targets_to_remove}")

        # Add new targets
        if targets_to_add:
            elbv2_client.register_targets(
                TargetGroupArn=TARGET_GROUP_ARN,
                Targets=[{'Id': ip, 'Port': CLUSTER_PORT} for ip in targets_to_add]
            )
            logger.info(f"Added targets: {targets_to_add}")

        if not targets_to_add and not targets_to_remove:
            logger.info("Target group is up to date")

        return {
            'success': True,
            'message': f"Updated target group. Current IPs: {current_ips}"
        }

    except Exception as e:
        logger.error(f"Error updating target group: {e}")
        return {
            'success': False,
            'message': f"Failed to update target group: {e}"
        }

def lambda_handler(event, context):
    logger.info(f"Handler invoked for cluster {CLUSTER_NAME}")

    result = update_target_group()
    status_code = 200 if result['success'] else 500

    logger.info(f"Function completed with status code {status_code}")

    return {
        'statusCode': status_code,
        'body': result['message']
    }
