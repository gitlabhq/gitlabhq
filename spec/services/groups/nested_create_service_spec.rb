# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::NestedCreateService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:organization) { create(:organization, users: [user]) }
  let(:visibility_level) { Gitlab::CurrentSettings.current_application_settings.default_group_visibility }

  subject(:service) { described_class.new(user, params) }

  shared_examples 'with a visibility level' do
    it 'creates the group with correct visibility level' do
      allow(Gitlab::CurrentSettings.current_application_settings)
        .to receive(:default_group_visibility) { Gitlab::VisibilityLevel::INTERNAL }

      group = service.execute

      expect(group.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    context 'adding a visibility level ' do
      it 'overwrites the visibility level' do
        service = described_class.new(user, params.merge(visibility_level: Gitlab::VisibilityLevel::PRIVATE))

        group = service.execute

        expect(group.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end
  end

  describe 'with subgroups' do
    let(:params) { { organization_id: organization.id, group_path: 'a-group/a-sub-group' } }

    describe "#execute" do
      it 'returns the group if it already existed' do
        parent = create(:group, path: 'a-group')
        child = create(:group, path: 'a-sub-group', parent: parent)

        parent.add_owner(user)
        child.add_owner(user)

        expect(service.execute).to eq(child)
      end

      it 'reuses a parent if it already existed' do
        parent = create(:group, path: 'a-group')
        parent.add_owner(user)

        expect(service.execute.parent).to eq(parent)
      end

      it 'creates group and subgroup in the database' do
        service.execute

        parent = Group.find_by_full_path('a-group')
        child = parent.children.find_by(path: 'a-sub-group')

        expect(parent).not_to be_nil
        expect(child).not_to be_nil
      end

      context 'when creating a new subgroup' do
        before do
          parent = create(:group, path: 'a-group')
          parent.add_owner(user)
        end

        it 'calls Groups::CreateService without organization_id' do
          create_service_params = {
            name: 'a-sub-group',
            path: 'a-sub-group',
            parent: Group.find_by(path: 'a-group'),
            visibility_level: visibility_level
          }

          expect(Groups::CreateService).to receive(:new)
            .with(user, create_service_params)
           .and_call_original

          service.execute

          child = Group.find_by_full_path(params[:group_path])
          expect(child).not_to be_nil
        end
      end

      it_behaves_like 'with a visibility level'
    end
  end
end
