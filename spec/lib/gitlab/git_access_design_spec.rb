# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccessDesign do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }

  let(:protocol) { 'web' }
  let(:actor) { user }

  subject(:access) do
    described_class.new(actor, project, protocol, authentication_abilities: [:read_project, :download_code, :push_code])
  end

  describe '#check' do
    subject { access.check('git-receive-pack', ::Gitlab::GitAccess::ANY) }

    before do
      enable_design_management
    end

    context 'when the user is allowed to manage designs' do
      it do
        is_expected.to be_a(::Gitlab::GitAccessResult::Success)
      end
    end

    context 'when the user is not allowed to manage designs' do
      let_it_be(:user) { create(:user) }

      it 'raises an error' do
        expect { subject }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
      end
    end

    context 'when the protocol is not web' do
      let(:protocol) { 'https' }

      it 'raises an error' do
        expect { subject }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
      end
    end

    context 'when the project organization is in maintenance mode' do
      let_it_be_with_reload(:organization) { create(:organization) }
      let_it_be(:project) { create(:project, organization: organization) }
      let_it_be(:user) { project.first_owner }

      context 'for a time-bounded maintenance reason' do
        before do
          organization.start_maintenance(maintenance_reason: 'migration')
          organization.confirm_maintenance
        end

        it 'blocks the request with the maintenance message' do
          expect { subject }.to raise_error(
            ::Gitlab::GitAccess::ForbiddenError,
            organization.maintenance_message)
        end
      end

      context 'for an indefinite maintenance reason' do
        before do
          organization.start_maintenance(maintenance_reason: 'legal')
          organization.confirm_maintenance
        end

        it 'blocks the request with the maintenance message' do
          expect { subject }.to raise_error(
            ::Gitlab::GitAccess::ForbiddenError,
            organization.maintenance_message)
        end
      end

      context 'when enforcement is disabled' do
        before do
          organization.start_maintenance(maintenance_reason: 'migration')
          organization.confirm_maintenance
          stub_feature_flags(organization_maintenance_enforcement: false)
        end

        it 'allows the request' do
          is_expected.to be_a(::Gitlab::GitAccessResult::Success)
        end
      end

      context 'when the container is a design repository' do
        let_it_be(:container) { create(:design_management_repository, project: project) }

        let(:access) do
          described_class.new(actor, container, protocol,
            authentication_abilities: [:read_project, :download_code, :push_code])
        end

        before do
          organization.start_maintenance(maintenance_reason: 'migration')
          organization.confirm_maintenance
          organization.reload
        end

        it 'resolves the organization via the project and blocks the request' do
          expect { subject }.to raise_error(
            ::Gitlab::GitAccess::ForbiddenError,
            'This organization is temporarily unavailable due to maintenance.')
        end
      end

      context 'when the container has no resolvable project' do
        let(:container) { instance_double(DesignManagement::Repository, project: nil) }

        let(:access) do
          described_class.new(actor, container, protocol,
            authentication_abilities: [:read_project, :download_code, :push_code])
        end

        before do
          organization.start_maintenance(maintenance_reason: 'migration')
          organization.confirm_maintenance
        end

        it 'does not enforce maintenance mode' do
          expect { access.send(:check_organization_maintenance!) }.not_to raise_error
        end
      end
    end
  end
end
