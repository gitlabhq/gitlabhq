require 'spec_helper'

describe Groups::NestedCreateService do
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

  describe 'without subgroups' do
    let(:params) { { group_path: 'a-group' } }

    before do
      allow(Group).to receive(:supports_nested_groups?) { false }
    end

    it 'creates the group' do
      group = service.execute

      expect(group).to be_persisted
    end

    it 'returns the group if it already existed' do
      existing_group = create(:group, path: 'a-group')

      expect(service.execute).to eq(existing_group)
    end

    it 'raises an error when tring to create a subgroup' do
      service = described_class.new(user, group_path: 'a-group/a-sub-group')

      expect { service.execute }.to raise_error('Nested groups are not supported on MySQL')
    end

    it_behaves_like 'with a visibility level'
  end

  describe 'with subgroups', :nested_groups do
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
