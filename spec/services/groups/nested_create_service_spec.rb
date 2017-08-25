require 'spec_helper'

describe Groups::NestedCreateService do
  let(:user) { create(:user) }
  let(:params) { { group_path: 'a-group/a-sub-group' } }

  subject(:service) { described_class.new(user, params) }

  describe "#execute" do
    it 'returns the group if it already existed' do
      parent = create(:group, path: 'a-group', owner: user)
      child = create(:group, path: 'a-sub-group', parent: parent, owner: user)

      expect(service.execute).to eq(child)
    end

    it 'reuses a parent if it already existed', :nested_groups do
      parent = create(:group, path: 'a-group')
      parent.add_owner(user)

      expect(service.execute.parent).to eq(parent)
    end

    it 'creates group and subgroup in the database', :nested_groups do
      service.execute

      parent = Group.find_by_full_path('a-group')
      child = parent.children.find_by(path: 'a-sub-group')

      expect(parent).not_to be_nil
      expect(child).not_to be_nil
    end

    it 'creates the group with correct visibility level' do
      allow(Gitlab::CurrentSettings.current_application_settings)
        .to receive(:default_group_visibility) { Gitlab::VisibilityLevel::INTERNAL }

      group = service.execute

      expect(group.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    context 'adding a visibility level ' do
      let(:params) { { group_path: 'a-group/a-sub-group', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

      it 'overwrites the visibility level' do
        group = service.execute

        expect(group.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end
  end
end
