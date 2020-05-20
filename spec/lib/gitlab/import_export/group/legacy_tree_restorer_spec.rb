# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::Group::LegacyTreeRestorer do
  include ImportExport::CommonUtil

  let(:shared) { Gitlab::ImportExport::Shared.new(group) }

  describe 'restore group tree' do
    before_all do
      # Using an admin for import, so we can check assignment of existing members
      user = create(:admin, email: 'root@gitlabexample.com')
      create(:user, email: 'adriene.mcclure@gitlabexample.com')
      create(:user, email: 'gwendolyn_robel@gitlabexample.com')

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

      context 'issue boards' do
        it 'has issue boards' do
          expect(@group.boards.count).to eq(1)
        end

        it 'has board label lists' do
          lists = @group.boards.find_by(name: 'first board').lists

          expect(lists.count).to eq(3)
          expect(lists.first.label.title).to eq('TSL')
          expect(lists.second.label.title).to eq('Sosync')
        end
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
        expect(@group.members.map(&:user).map(&:email)).to contain_exactly('root@gitlabexample.com', 'adriene.mcclure@gitlabexample.com', 'gwendolyn_robel@gitlabexample.com')
      end
    end
  end

  context 'excluded attributes' do
    let!(:source_user) { create(:user, id: 123) }
    let!(:importer_user) { create(:user) }
    let(:group) { create(:group) }
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:group_tree_restorer) { described_class.new(user: importer_user, shared: shared, group: group, group_hash: nil) }
    let(:group_json) { ActiveSupport::JSON.decode(IO.read(File.join(shared.export_path, 'group.json'))) }

    shared_examples 'excluded attributes' do
      excluded_attributes = %w[
        id
        owner_id
        parent_id
        created_at
        updated_at
        runners_token
        runners_token_encrypted
        saml_discovery_token
      ]

      before do
        group.add_owner(importer_user)

        setup_import_export_config('group_exports/complex')
      end

      excluded_attributes.each do |excluded_attribute|
        it 'does not allow override of excluded attributes' do
          expect(group_json[excluded_attribute]).not_to eq(group.public_send(excluded_attribute))
        end
      end
    end

    include_examples 'excluded attributes'
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

  context 'group visibility levels' do
    let(:user) { create(:user) }
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:group_tree_restorer) { described_class.new(user: user, shared: shared, group: group, group_hash: nil) }

    before do
      setup_import_export_config(filepath)

      group_tree_restorer.restore
    end

    shared_examples 'with visibility level' do |visibility_level, expected_visibilities|
      context "when visibility level is #{visibility_level}" do
        let(:group) { create(:group, visibility_level) }
        let(:filepath) { "group_exports/visibility_levels/#{visibility_level}" }

        it "imports all subgroups as #{visibility_level}" do
          expect(group.children.map(&:visibility_level)).to match_array(expected_visibilities)
        end
      end
    end

    include_examples 'with visibility level', :public, [20, 10, 0]
    include_examples 'with visibility level', :private, [0, 0, 0]
    include_examples 'with visibility level', :internal, [10, 10, 0]
  end
end
