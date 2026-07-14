# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccess, :aggregate_failures, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }

  let(:actor) { user }
  let(:organization) { create(:organization) }
  let(:project) { create(:project, :repository, organization: organization) }
  let(:repository_path) { "#{project.full_path}.git" }
  let(:protocol) { 'ssh' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }
  let(:auth_result_type) { nil }
  let(:gitaly_context) { { 'key' => 'value' } }
  let(:personal_access_token) { nil }
  let(:changes) { Gitlab::GitAccess::ANY }
  let(:push_access_check) { access.check('git-receive-pack', changes) }
  let(:pull_access_check) { access.check('git-upload-pack', changes) }

  let(:access_class) do
    Class.new(described_class) do
      def push_ability
        :push_code
      end

      def download_ability
        :download_code
      end
    end
  end

  before do
    project.add_maintainer(user)
  end

  describe '#check_organization_read_only!' do
    context 'with the organization read-only enforcement feature flag enabled' do
      before do
        stub_feature_flags(organization_read_only_enforcement: true)
      end

      context 'when the project organization is read-only' do
        before do
          organization.start_read_only(read_only_reason: 'migration')
          organization.confirm_read_only
        end

        it 'blocks push access and allows pull access' do
          expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:organization_read_only])
          expect { pull_access_check }.not_to raise_error
        end
      end

      context 'when the project organization is active' do
        it 'allows push access' do
          expect { push_access_check }.not_to raise_error
        end
      end

      context 'when the container does not expose an organization' do
        before do
          allow(project).to receive(:respond_to?).and_call_original
          allow(project).to receive(:respond_to?).with(:organization).and_return(false)
        end

        it 'allows push access' do
          expect { push_access_check }.not_to raise_error
        end
      end
    end

    context 'with the organization read-only enforcement feature flag disabled' do
      before do
        stub_feature_flags(organization_read_only_enforcement: false)
        organization.start_read_only(read_only_reason: 'migration')
        organization.confirm_read_only
      end

      it 'allows push access' do
        expect { push_access_check }.not_to raise_error
      end
    end
  end

  private

  def access
    access_class.new(actor, project, protocol,
      authentication_abilities: authentication_abilities,
      repository_path: repository_path,
      redirected_path: redirected_path, auth_result_type: auth_result_type, gitaly_context: gitaly_context,
      personal_access_token: personal_access_token)
  end

  def raise_forbidden(message)
    raise_error(described_class::ForbiddenError, message)
  end
end
