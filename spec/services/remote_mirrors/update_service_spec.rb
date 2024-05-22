# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirrors::UpdateService, feature_category: :source_code_management do
  subject(:service) { described_class.new(project, user, params) }

  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let!(:remote_mirror) { create(:remote_mirror, project: project) }

  let(:params) do
    {
      url: url,
      enabled: enabled,
      auth_method: auth_method,
      user: cred_user,
      password: cred_password,
      only_protected_branches: only_protected_branches
    }
  end

  let(:url) { 'https://example.com' }
  let(:enabled) { true }
  let(:auth_method) { 'password' }
  let(:cred_user) { 'admin' }
  let(:cred_password) { 'pass' }
  let(:only_protected_branches) { true }

  describe '#execute', :aggregate_failures do
    subject(:execute) { service.execute(remote_mirror) }

    let(:updated_remote_mirror) { execute.payload[:remote_mirror] }

    it 'updates a push mirror' do
      is_expected.to be_success

      expect(updated_remote_mirror).to have_attributes(
        url: "https://#{cred_user}:#{cred_password}@example.com",
        enabled: enabled,
        auth_method: auth_method,
        user: cred_user,
        password: cred_password,
        only_protected_branches: only_protected_branches,
        project: project
      )
    end

    context 'when remote mirror project does not match provided project' do
      let(:remote_mirror) { create(:remote_mirror, project: build(:project)) }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('Project mismatch')
      end
    end

    context 'when user does not have permissions' do
      let(:user) { nil }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('Access Denied')
      end
    end

    context 'when remote mirror is missing' do
      let(:remote_mirror) { nil }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('Remote mirror is missing')
      end
    end

    context 'when params are invalid' do
      let(:auth_method) { 'wrong' }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message.full_messages).to include('Auth method is not included in the list')
      end
    end
  end
end
