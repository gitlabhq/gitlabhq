# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Aws::ProvisionService do
  describe '#execute' do
    let(:provider) { create(:cluster_provider_aws) }

    let(:provision_role) { create(:aws_role, user: provider.created_by_user) }
    let(:client) { instance_double(Aws::CloudFormation::Client, create_stack: true) }
    let(:cloudformation_template) { double }
    let(:credentials) do
      instance_double(
        Aws::Credentials,
        access_key_id: 'key',
        secret_access_key: 'secret',
        session_token: 'token'
      )
    end

    let(:parameters) do
      [
        { parameter_key: 'ClusterName', parameter_value: provider.cluster.name },
        { parameter_key: 'ClusterRole', parameter_value: provider.role_arn },
        { parameter_key: 'ClusterControlPlaneSecurityGroup', parameter_value: provider.security_group_id },
        { parameter_key: 'VpcId', parameter_value: provider.vpc_id },
        { parameter_key: 'Subnets', parameter_value: provider.subnet_ids.join(',') },
        { parameter_key: 'NodeAutoScalingGroupDesiredCapacity', parameter_value: provider.num_nodes.to_s },
        { parameter_key: 'NodeInstanceType', parameter_value: provider.instance_type },
        { parameter_key: 'KeyName', parameter_value: provider.key_name }
      ]
    end

    subject { described_class.new.execute(provider) }

    before do
      allow(Clusters::Aws::FetchCredentialsService).to receive(:new)
        .with(provision_role, provider: provider)
        .and_return(double(execute: credentials))

      allow(provider).to receive(:api_client)
        .and_return(client)

      allow(File).to receive(:read)
        .with(Rails.root.join('vendor', 'aws', 'cloudformation', 'eks_cluster.yaml'))
        .and_return(cloudformation_template)
    end

    it 'updates the provider status to :creating and configures the provider with credentials' do
      subject

      expect(provider).to be_creating
      expect(provider.access_key_id).to eq 'key'
      expect(provider.secret_access_key).to eq 'secret'
      expect(provider.session_token).to eq 'token'
    end

    it 'creates a CloudFormation stack' do
      expect(client).to receive(:create_stack).with(
        stack_name: provider.cluster.name,
        template_body: cloudformation_template,
        parameters: parameters,
        capabilities: ["CAPABILITY_IAM"]
      )

      subject
    end

    it 'schedules a worker to monitor creation status' do
      expect(WaitForClusterCreationWorker).to receive(:perform_in)
        .with(Clusters::Aws::VerifyProvisionStatusService::INITIAL_INTERVAL, provider.cluster_id)

      subject
    end

    describe 'error handling' do
      shared_examples 'provision error' do |message|
        it "sets the status to :errored with an appropriate error message" do
          subject

          expect(provider).to be_errored
          expect(provider.status_reason).to include(message)
        end
      end

      context 'invalid state transition' do
        before do
          allow(provider).to receive(:make_creating).and_return(false)
        end

        include_examples 'provision error', 'Failed to update provider record'
      end

      context 'AWS role is not configured' do
        before do
          allow(Clusters::Aws::FetchCredentialsService).to receive(:new)
            .and_raise(Clusters::Aws::FetchCredentialsService::MissingRoleError)
        end

        include_examples 'provision error', 'Amazon role is not configured'
      end

      context 'AWS credentials are not configured' do
        before do
          allow(Clusters::Aws::FetchCredentialsService).to receive(:new)
            .and_raise(Aws::Errors::MissingCredentialsError)
        end

        include_examples 'provision error', 'Amazon credentials are not configured'
      end

      context 'Authentication failure' do
        before do
          allow(Clusters::Aws::FetchCredentialsService).to receive(:new)
            .and_raise(Aws::STS::Errors::ServiceError.new(double, 'Error message'))
        end

        include_examples 'provision error', 'Amazon authentication failed'
      end

      context 'CloudFormation failure' do
        before do
          allow(client).to receive(:create_stack)
            .and_raise(Aws::CloudFormation::Errors::ServiceError.new(double, 'Error message'))
        end

        include_examples 'provision error', 'Amazon CloudFormation request failed'
      end
    end
  end
end
