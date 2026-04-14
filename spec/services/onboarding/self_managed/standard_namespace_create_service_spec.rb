# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::SelfManaged::StandardNamespaceCreateService, feature_category: :onboarding do
  let_it_be(:organization) { create(:organization) }
  let(:group_params) do
    {
      name: 'My Group',
      path: 'my-group',
      visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s,
      organization_id: organization.id
    }
  end

  let(:project_params) do
    {
      name: 'My Project',
      path: 'my-project',
      visibility_level: Gitlab::VisibilityLevel::PRIVATE
    }
  end

  let_it_be(:user) { create(:user, can_create_group: true) }

  before_all do
    organization.users << user
  end

  subject(:service) { described_class.new(user, group_params: group_params, project_params: project_params) }

  describe '#execute' do
    context 'when group and project are valid' do
      it 'returns success' do
        expect(service.execute).to be_success
      end

      it 'creates the group' do
        expect { service.execute }.to change { Group.count }.by(1)
      end

      it 'creates the project' do
        expect { service.execute }.to change { Project.count }.by(1)
      end

      it 'returns the group and project in the payload' do
        result = service.execute

        expect(result.payload[:group]).to be_a(Group).and be_persisted
        expect(result.payload[:project]).to be_a(Project).and be_persisted
      end

      it 'sets organization_id on the project from the group' do
        result = service.execute

        expect(result.payload[:project].organization_id).to eq(organization.id)
      end

      it 'creates the project under the new group' do
        result = service.execute

        expect(result.payload[:project].namespace).to eq(result.payload[:group])
      end

      it 'assigns the user as owner of the group' do
        result = service.execute

        expect(result.payload[:group].owners).to include(user)
      end
    end

    context 'when group path is blank but name is present' do
      let(:group_params) { super().merge(path: '', name: 'My Cool Group') }

      it 'generates the path from the name using Namespace.clean_path' do
        expect(Namespace).to receive(:clean_path).with('My Cool Group').and_return('my-cool-group')

        result = service.execute

        expect(result.payload[:group].path).to eq('my-cool-group')
      end

      it 'returns success' do
        expect(service.execute).to be_success
      end
    end

    context 'when group name contains only special characters' do
      let(:group_params) { super().merge(path: '', name: '!!') }

      it 'generates a valid non-blank path via Namespace.clean_path' do
        result = service.execute

        expect(result.payload[:group].path).not_to be_blank
      end
    end

    context 'when group creation fails' do
      let(:group_params) { super().merge(name: '', path: '') }

      it 'returns an error' do
        expect(service.execute).to be_error
      end

      it 'does not create any group' do
        expect { service.execute }.not_to change { Group.count }
      end

      it 'does not create any project' do
        expect { service.execute }.not_to change { Project.count }
      end

      it 'returns the group and a new project in the payload' do
        result = service.execute

        expect(result.payload[:group]).to be_a(Group)
        expect(result.payload[:project]).to be_a(Project)
      end

      it 'includes the project params in the payload project' do
        result = service.execute

        expect(result.payload[:project].name).to eq('My Project')
      end

      it 'returns the group creation error message' do
        result = service.execute

        expect(result.message).to eq(s_('Onboarding|Group failed to be created'))
      end
    end

    context 'when project creation fails' do
      let(:project_params) { super().merge(name: '', path: '') }

      it 'returns an error' do
        expect(service.execute).to be_error
      end

      # NOTE: The service intentionally does NOT wrap group + project creation
      # in a transaction. This runs once during SM root admin first-login
      # onboarding - the group persists even when the project fails so the
      # controller can re-render the form without losing it. If this changes,
      # add transaction rollback coverage.
      it 'persists the group even when the project fails (no transaction)' do
        result = service.execute

        expect(result.payload[:group]).to be_persisted
        expect(result.payload[:project]).not_to be_persisted
      end

      it 'returns the project creation error message' do
        result = service.execute

        expect(result.message).to eq(s_('Onboarding|Project failed to be created'))
      end
    end

    context 'when the user cannot create groups' do
      # Use `let` (not `let_it_be`) so the outer `before_all` org membership
      # doesn't apply. Re-add org membership here to isolate the
      # can_create_group gate from any organization-level permission checks.
      let(:user) { create(:user, can_create_group: false) }

      before do
        organization.users << user
      end

      it 'returns an error' do
        expect(service.execute).to be_error
      end

      it 'does not create a group or project' do
        expect { service.execute }
          .to not_change { Group.count }
          .and not_change { Project.count }
      end
    end

    context 'when both group and project params are invalid (group fails first)' do
      let(:group_params) { super().merge(name: '', path: '') }
      let(:project_params) { super().merge(name: '', path: '') }

      # Group creation fails before project creation is attempted,
      # so only the group creation error message is returned.
      it 'returns an error with the group creation message' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq(s_('Onboarding|Group failed to be created'))
      end
    end

    context 'when group_params includes organization_id' do
      it 'uses the provided organization_id' do
        result = service.execute

        expect(result.payload[:group].organization_id).to eq(organization.id)
      end
    end
  end
end
