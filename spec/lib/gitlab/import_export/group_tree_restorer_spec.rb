# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::GroupTreeRestorer do
  include ImportExport::CommonUtil

  let(:shared) { Gitlab::ImportExport::Shared.new(group) }

  describe 'restore group tree' do
    before(:context) do
      # Using an admin for import, so we can check assignment of existing members
      user = create(:admin, username: 'root')
      create(:user, username: 'adriene.mcclure')
      create(:user, username: 'gwendolyn_robel')

      RSpec::Mocks.with_temporary_scope do
        @group = create(:group, name: 'group', path: 'group')
        @shared = Gitlab::ImportExport::Shared.new(@group)

        setup_import_export_config('group_exports/complex')

        group_tree_restorer = described_class.new(user: user, shared: @shared, group: @group, group_hash: nil)

        @restored_group_json = group_tree_restorer.restore
      end
    end

    context 'JSON' do
      it 'restores models based on JSON' do
        expect(@restored_group_json).to be_truthy
      end

      it 'has the group description' do
        expect(Group.find_by_path('group').description).to eq('Group Description')
      end

      it 'has group labels' do
        expect(@group.labels.count).to eq(10)
      end

      it 'has issue boards' do
        expect(@group.boards.count).to eq(2)
      end

      it 'has badges' do
        expect(@group.badges.count).to eq(1)
      end

      it 'has milestones' do
        expect(@group.milestones.count).to eq(5)
      end

      it 'has group children' do
        expect(@group.children.count).to eq(2)
      end

      it 'has group members' do
        expect(@group.members.map(&:user).map(&:username)).to contain_exactly('root', 'adriene.mcclure', 'gwendolyn_robel')
      end
    end
  end

  context 'group.json file access check' do
    let(:user) { create(:user) }
    let!(:group) { create(:group, name: 'group2', path: 'group2') }
    let(:group_tree_restorer) { described_class.new(user: user, shared: shared, group: group, group_hash: nil) }
    let(:restored_group_json) { group_tree_restorer.restore }

    it 'does not read a symlink' do
      Dir.mktmpdir do |tmpdir|
        setup_symlink(tmpdir, 'group.json')
        allow(shared).to receive(:export_path).and_call_original

        expect(group_tree_restorer.restore).to eq(false)
        expect(shared.errors).to include('Incorrect JSON format')
      end
    end
  end
end
