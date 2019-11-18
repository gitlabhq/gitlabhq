# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::GroupTreeSaver do
  describe 'saves the group tree into a json object' do
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:group_tree_saver) { described_class.new(group: group, current_user: user, shared: shared) }
    let(:export_path) { "#{Dir.tmpdir}/group_tree_saver_spec" }
    let(:user) { create(:user) }
    let!(:group) { setup_group }

    before do
      group.add_maintainer(user)
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves group successfully' do
      expect(group_tree_saver.save).to be true
    end

    context ':export_fast_serialize feature flag checks' do
      before do
        expect(Gitlab::ImportExport::Reader).to receive(:new).with(shared: shared, config: group_config).and_return(reader)
        expect(reader).to receive(:group_tree).and_return(group_tree)
      end

      let(:reader) { instance_double('Gitlab::ImportExport::Reader') }
      let(:group_config) { Gitlab::ImportExport::Config.new(config: Gitlab::ImportExport.group_config_file).to_h }
      let(:group_tree) do
        {
          include: [{ milestones: { include: [] } }],
          preload: { milestones: nil }
        }
      end

      context 'when :export_fast_serialize feature is enabled' do
        let(:serializer) { instance_double(Gitlab::ImportExport::FastHashSerializer) }

        before do
          stub_feature_flags(export_fast_serialize: true)

          expect(Gitlab::ImportExport::FastHashSerializer).to receive(:new).with(group, group_tree).and_return(serializer)
        end

        it 'uses FastHashSerializer' do
          expect(serializer).to receive(:execute)

          group_tree_saver.save
        end
      end

      context 'when :export_fast_serialize feature is disabled' do
        before do
          stub_feature_flags(export_fast_serialize: false)
        end

        it 'is serialized via built-in `as_json`' do
          expect(group).to receive(:as_json).with(group_tree).and_call_original

          group_tree_saver.save
        end
      end
    end

    # It is mostly duplicated in
    # `spec/lib/gitlab/import_export/fast_hash_serializer_spec.rb`
    # except:
    # context 'with description override' do
    # context 'group members' do
    # ^ These are specific for the groupTreeSaver
    context 'JSON' do
      let(:saved_group_json) do
        group_tree_saver.save
        group_json(group_tree_saver.full_path)
      end

      it 'saves the correct json' do
        expect(saved_group_json).to include({ 'description' => 'description', 'visibility_level' => 20 })
      end

      it 'has milestones' do
        expect(saved_group_json['milestones']).not_to be_empty
      end

      it 'has labels' do
        expect(saved_group_json['labels']).not_to be_empty
      end

      it 'has boards' do
        expect(saved_group_json['boards']).not_to be_empty
      end

      it 'has group members' do
        expect(saved_group_json['members']).not_to be_empty
      end

      it 'has priorities associated to labels' do
        expect(saved_group_json['labels'].first['priorities']).not_to be_empty
      end

      it 'has badges' do
        expect(saved_group_json['badges']).not_to be_empty
      end

      context 'group children' do
        let(:children) { group.children }

        it 'exports group children' do
          expect(saved_group_json['children'].length).to eq(children.count)
        end

        it 'exports group children of children' do
          expect(saved_group_json['children'].first['children'].length).to eq(children.first.children.count)
        end
      end

      context 'group members' do
        let(:user2) { create(:user, email: 'group@member.com') }
        let(:member_emails) do
          saved_group_json['members'].map do |pm|
            pm['user']['email']
          end
        end

        before do
          group.add_developer(user2)
        end

        it 'exports group members as group owner' do
          group.add_owner(user)

          expect(member_emails).to include('group@member.com')
        end

        context 'as admin' do
          let(:user) { create(:admin) }

          it 'exports group members as admin' do
            expect(member_emails).to include('group@member.com')
          end

          it 'exports group members' do
            member_types = saved_group_json['members'].map { |pm| pm['source_type'] }

            expect(member_types).to all(eq('Namespace'))
          end
        end
      end

      context 'group attributes' do
        it 'does not contain the runners token' do
          expect(saved_group_json).not_to include("runners_token" => 'token')
        end
      end
    end
  end

  def setup_group
    group = create(:group, description: 'description')
    sub_group = create(:group, description: 'description', parent: group)
    create(:group, description: 'description', parent: sub_group)
    create(:milestone, group: group)
    create(:group_badge, group: group)
    group_label = create(:group_label, group: group)
    create(:label_priority, label: group_label, priority: 1)
    create(:board, group: group)
    create(:group_badge, group: group)

    group
  end

  def group_json(filename)
    JSON.parse(IO.read(filename))
  end
end
