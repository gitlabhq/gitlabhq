# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccess, :aggregate_failures, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }

  let(:actor) { user }
  let(:organization) { create(:organization) }
  let(:project) { create(:project, :small_repo, organization: organization) }
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

  describe '#check_organization_maintenance!' do
    context 'with the organization maintenance enforcement feature flag enabled' do
      before do
        stub_feature_flags(organization_maintenance_enforcement: true)
      end

      context 'when the project organization is in maintenance for a time-bounded reason' do
        before do
          organization.start_maintenance(maintenance_reason: 'migration')
          organization.confirm_maintenance
        end

        it 'blocks both push and pull access with the time-bounded maintenance message' do
          expect { push_access_check }.to raise_forbidden(organization.maintenance_message)
          expect { pull_access_check }.to raise_forbidden(organization.maintenance_message)
        end
      end

      context 'when the project organization is in maintenance for an indefinite reason' do
        before do
          organization.start_maintenance(maintenance_reason: 'legal')
          organization.confirm_maintenance
        end

        it 'blocks both push and pull access with the indefinite maintenance message' do
          expect { push_access_check }.to raise_forbidden(organization.maintenance_message)
          expect { pull_access_check }.to raise_forbidden(organization.maintenance_message)
        end
      end

      context 'when the project organization is active' do
        it 'allows push and pull access' do
          expect { push_access_check }.not_to raise_error
          expect { pull_access_check }.not_to raise_error
        end
      end

      context 'when the container does not expose an organization' do
        before do
          allow(project).to receive(:respond_to?).and_call_original
          allow(project).to receive(:respond_to?).with(:organization).and_return(false)
        end

        it 'allows push and pull access' do
          expect { push_access_check }.not_to raise_error
          expect { pull_access_check }.not_to raise_error
        end
      end

      context 'when the actor has no access to the project' do
        let(:actor) { create(:user) }

        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          organization.start_maintenance(maintenance_reason: 'migration')
          organization.confirm_maintenance
        end

        it 'raises the access error rather than disclosing the maintenance status' do
          expect { pull_access_check }.to raise_error do |error|
            expect(error.message).not_to eq(organization.maintenance_message)
          end
        end
      end
    end

    context 'with the organization maintenance enforcement feature flag disabled' do
      before do
        stub_feature_flags(organization_maintenance_enforcement: false)
        organization.start_maintenance(maintenance_reason: 'migration')
        organization.confirm_maintenance
      end

      it 'allows push and pull access' do
        expect { push_access_check }.not_to raise_error
        expect { pull_access_check }.not_to raise_error
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
