# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Aws::AuthorizeRoleService do
  let(:user) { create(:user) }
  let(:credentials) { instance_double(Aws::Credentials) }
  let(:credentials_service) { instance_double(Clusters::Aws::FetchCredentialsService, execute: credentials) }

  let(:params) do
    params = ActionController::Parameters.new({
      cluster: {
        role_arn: 'arn:my-role',
        role_external_id: 'external-id'
      }
    })

    params.require(:cluster).permit(:role_arn, :role_external_id)
  end

  subject { described_class.new(user, params: params).execute }

  before do
    allow(Clusters::Aws::FetchCredentialsService).to receive(:new)
      .with(instance_of(Aws::Role)).and_return(credentials_service)
  end

  context 'role does not exist' do
    it 'creates an Aws::Role record and returns a set of credentials' do
      expect(user).to receive(:create_aws_role!)
        .with(params).and_call_original

      expect(subject.status).to eq(:ok)
      expect(subject.body).to eq(credentials)
    end
  end

  context 'role already exists' do
    let(:role) { create(:aws_role, user: user) }

    it 'updates the existing Aws::Role record and returns a set of credentials' do
      expect(role).to receive(:update!)
        .with(params).and_call_original

      expect(subject.status).to eq(:ok)
      expect(subject.body).to eq(credentials)
    end
  end

  context 'errors' do
    shared_examples 'bad request' do
      it 'returns an empty hash' do
        expect(subject.status).to eq(:unprocessable_entity)
        expect(subject.body).to eq({})
      end
    end

    context 'cannot create role' do
      before do
        allow(user).to receive(:create_aws_role!)
          .and_raise(ActiveRecord::RecordInvalid.new(user))
      end

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
