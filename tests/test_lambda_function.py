import os
from unittest.mock import patch, MagicMock
from lambda_function import lambda_handler


def test_handler_when_nothing_is_found():
    fake_ec2 = MagicMock()
    fake_ec2.describe_instances.return_value = {'Reservations': []}
    fake_ec2.describe_addresses.return_value = {'Addresses': []}
    fake_ec2.describe_volumes.return_value = {'Volumes': []}

    fake_ce = MagicMock()
    fake_ce.get_cost_and_usage.return_value = {
        'ResultsByTime': [{'Total': {'UnblendedCost': {'Amount': '12.5'}}}]
    }

    fake_sns = MagicMock()
    fakes = {'ec2': fake_ec2, 'ce': fake_ce, 'sns': fake_sns}

    with patch.dict(os.environ, {'SNS_TOPIC_ARN': 'arn:aws:sns:us-east-1:123456789012:test'}):
        with patch('lambda_function.boto3.client', side_effect=lambda name: fakes[name]):
            result = lambda_handler({}, None)

    assert result == {
        'IdleInstances': [],
        'UnusedVolumes': [],
        'UnusedAddresses': [],
        'TotalEC2CostLast30Days': 12.5,
    }
    fake_sns.publish.assert_called_once()