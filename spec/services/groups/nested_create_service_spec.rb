# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::NestedCreateService, feature_category: :groups_and_projects do
  let(:user) { create(:user) }

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
    let(:params) { { group_path: 'a-group/a-sub-group' } }

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

      it_behaves_like 'with a visibility level'
    end
  end
end
