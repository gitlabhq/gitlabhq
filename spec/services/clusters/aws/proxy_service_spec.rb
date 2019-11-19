# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Aws::ProxyService do
  let(:role) { create(:aws_role) }
  let(:credentials) { instance_double(Aws::Credentials) }
  let(:client_instance) { instance_double(client) }

  let(:region) { 'region' }
  let(:vpc_id) { }
  let(:params) do
    ActionController::Parameters.new({
      resource: resource,
      region: region,
      vpc_id: vpc_id
    })
  end

  subject { described_class.new(role, params: params).execute }

  context 'external resources' do
    before do
      allow(Clusters::Aws::FetchCredentialsService).to receive(:new) do
        double(execute: credentials)
      end

      allow(client).to receive(:new)
        .with(
          credentials: credentials, region: region,
          http_open_timeout: 5, http_read_timeout: 10)
        .and_return(client_instance)
    end

    shared_examples 'bad request' do
      it 'returns an empty hash' do
        expect(subject.status).to eq :bad_request
        expect(subject.body).to eq({})
      end
    end

    describe 'key_pairs' do
      let(:client) { Aws::EC2::Client }
      let(:resource) { 'key_pairs' }
      let(:response) { double(to_hash: :key_pairs) }

      it 'requests a list of key pairs' do
        expect(client_instance).to receive(:describe_key_pairs).once.and_return(response)
        expect(subject.status).to eq :ok
        expect(subject.body).to eq :key_pairs
      end
    end

    describe 'roles' do
      let(:client) { Aws::IAM::Client }
      let(:resource) { 'roles' }
      let(:response) { double(to_hash: :roles) }

      it 'requests a list of roles' do
        expect(client_instance).to receive(:list_roles).once.and_return(response)
        expect(subject.status).to eq :ok
        expect(subject.body).to eq :roles
      end
    end

    describe 'regions' do
      let(:client) { Aws::EC2::Client }
      let(:resource) { 'regions' }
      let(:response) { double(to_hash: :regions) }

      it 'requests a list of regions' do
        expect(client_instance).to receive(:describe_regions).once.and_return(response)
        expect(subject.status).to eq :ok
        expect(subject.body).to eq :regions
      end
    end

    describe 'security_groups' do
      let(:client) { Aws::EC2::Client }
      let(:resource) { 'security_groups' }
      let(:response) { double(to_hash: :security_groups) }

      include_examples 'bad request'

      context 'VPC is specified' do
        let(:vpc_id) { 'vpc-1' }

        it 'requests a list of security groups for a VPC' do
          expect(client_instance).to receive(:describe_security_groups).once
            .with(filters: [{ name: 'vpc-id', values: [vpc_id] }])
            .and_return(response)
          expect(subject.status).to eq :ok
          expect(subject.body).to eq :security_groups
        end
      end
    end

    describe 'subnets' do
      let(:client) { Aws::EC2::Client }
      let(:resource) { 'subnets' }
      let(:response) { double(to_hash: :subnets) }

      include_examples 'bad request'

      context 'VPC is specified' do
        let(:vpc_id) { 'vpc-1' }

        it 'requests a list of subnets for a VPC' do
          expect(client_instance).to receive(:describe_subnets).once
            .with(filters: [{ name: 'vpc-id', values: [vpc_id] }])
            .and_return(response)
          expect(subject.status).to eq :ok
          expect(subject.body).to eq :subnets
        end
      end
    end

    describe 'vpcs' do
      let(:client) { Aws::EC2::Client }
      let(:resource) { 'vpcs' }
      let(:response) { double(to_hash: :vpcs) }

      it 'requests a list of VPCs' do
        expect(client_instance).to receive(:describe_vpcs).once.and_return(response)
        expect(subject.status).to eq :ok
        expect(subject.body).to eq :vpcs
      end
    end

    context 'errors' do
      let(:client) { Aws::EC2::Client }

      context 'unknown resource' do
        let(:resource) { 'instances' }

        include_examples 'bad request'
      end

      context 'client and configuration errors' do
        let(:resource) { 'vpcs' }

        before do
          allow(client_instance).to receive(:describe_vpcs).and_raise(error)
        end

        context 'error fetching credentials' do
          let(:error) { Aws::STS::Errors::ServiceError.new(nil, 'error message') }

          include_examples 'bad request'
        end

        context 'credentials not configured' do
          let(:error) { Aws::Errors::MissingCredentialsError.new('error message') }

          include_examples 'bad request'
        end

        context 'role not configured' do
          let(:error) { Clusters::Aws::FetchCredentialsService::MissingRoleError.new('error message') }

          include_examples 'bad request'
        end

        context 'EC2 error' do
          let(:error) { Aws::EC2::Errors::ServiceError.new(nil, 'error message') }

          include_examples 'bad request'
        end

        context 'IAM error' do
          let(:error) { Aws::IAM::Errors::ServiceError.new(nil, 'error message') }

          include_examples 'bad request'
        end

        context 'STS error' do
          let(:error) { Aws::STS::Errors::ServiceError.new(nil, 'error message') }

          include_examples 'bad request'
        end
      end
    end
  end

  context 'local resources' do
    describe 'instance_types' do
      let(:resource) { 'instance_types' }
      let(:cloudformation_template) { double }
      let(:instance_types) { double(dig: %w(t3.small)) }

      before do
        allow(File).to receive(:read)
          .with(Rails.root.join('vendor', 'aws', 'cloudformation', 'eks_cluster.yaml'))
          .and_return(cloudformation_template)

        allow(YAML).to receive(:safe_load)
          .with(cloudformation_template)
          .and_return(instance_types)
      end

      it 'returns a list of instance types' do
        expect(subject.status).to eq :ok
        expect(subject.body).to have_key(:instance_types)
        expect(subject.body[:instance_types]).to match_array([
          instance_type_name: 't3.small'
        ])
      end
    end
  end
end
