# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Aws::AuthorizeRoleService do
  subject { described_class.new(user, params: params).execute }

  let(:role) { create(:aws_role) }
  let(:user) { role.user }
  let(:credentials) { instance_double(Aws::Credentials) }
  let(:credentials_service) { instance_double(Clusters::Aws::FetchCredentialsService, execute: credentials) }

  let(:role_arn) { 'arn:my-role' }
  let(:region) { 'region' }
  let(:params) do
    params = ActionController::Parameters.new({
      cluster: {
        role_arn: role_arn,
        region: region
      }
    })

    params.require(:cluster).permit(:role_arn, :region)
  end

  before do
    allow(Clusters::Aws::FetchCredentialsService).to receive(:new)
      .with(instance_of(Aws::Role)).and_return(credentials_service)
  end

  context 'role exists' do
    it 'updates the existing Aws::Role record and returns a set of credentials' do
      expect(subject.status).to eq(:ok)
      expect(subject.body).to eq(credentials)
      expect(role.reload.role_arn).to eq(role_arn)
    end
  end

  context 'errors' do
    shared_examples 'bad request' do
      it 'returns an empty hash' do
        expect(subject.status).to eq(:unprocessable_entity)
        expect(subject.body).to eq({})
      end

      it 'logs the error' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)

        subject
      end
    end

    context 'role does not exist' do
      let(:user) { create(:user) }

      include_examples 'bad request'
    end

    context 'supplied ARN is invalid' do
      let(:role_arn) { 'invalid' }

      include_examples 'bad request'
    end

    context 'client errors' do
      before do
        allow(credentials_service).to receive(:execute).and_raise(error)
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
    end
  end
end
