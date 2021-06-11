# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::TreeSaver do
  describe 'saves the group tree into a json object' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { setup_groups }

    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:export_path) { "#{Dir.tmpdir}/group_tree_saver_spec" }

    subject(:group_tree_saver) { described_class.new(group: group, current_user: user, shared: shared) }

    before_all do
      group.add_maintainer(user)
    end

    before do
      allow_next_instance_of(Gitlab::ImportExport) do |import_export|
        allow(import_export).to receive(:storage_path).and_return(export_path)
      end
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves the group successfully' do
      expect(group_tree_saver.save).to be true
    end

    it 'fails to export a group' do
      allow_next_instance_of(Gitlab::ImportExport::Json::NdjsonWriter) do |ndjson_writer|
        allow(ndjson_writer).to receive(:write_relation_array).and_raise(RuntimeError, 'exception')
      end

      expect(shared).to receive(:error).with(RuntimeError).and_call_original

      expect(group_tree_saver.save).to be false
    end

    context 'exported files' do
      before do
        group_tree_saver.save
      end

      it 'has one group per line' do
        groups_catalog =
          File.readlines(exported_path_for('_all.ndjson'))
          .map { |line| Integer(line) }

        expect(groups_catalog.size).to eq(3)
        expect(groups_catalog).to eq([
          group.id,
          group.descendants.first.id,
          group.descendants.first.descendants.first.id
        ])
      end

      it 'has a file per group' do
        group.self_and_descendants.pluck(:id).each do |id|
          group_attributes_file = exported_path_for("#{id}.json")

          expect(File.exist?(group_attributes_file)).to be(true)
        end
      end

      context 'group attributes file' do
        let(:group_attributes_file) { exported_path_for("#{group.id}.json") }
        let(:group_attributes) { ::JSON.parse(File.read(group_attributes_file)) }

        it 'has a file for each group with its attributes' do
          expect(group_attributes['description']).to eq(group.description)
          expect(group_attributes['parent_id']).to eq(group.parent_id)
        end

        shared_examples 'excluded attributes' do
          excluded_attributes = %w[
            owner_id
            created_at
            updated_at
            runners_token
            runners_token_encrypted
            saml_discovery_token
          ]

          excluded_attributes.each do |excluded_attribute|
            it 'does not contain excluded attribute' do
              expect(group_attributes).not_to include(excluded_attribute => group.public_send(excluded_attribute))
            end
          end
        end

        include_examples 'excluded attributes'
      end

      it 'has a file for each group association' do
        group.self_and_descendants do |g|
          %w[
            badges
            boards
            epics
            labels
            members
            milestones
          ].each do |association|
            path = exported_path_for("#{g.id}", "#{association}.ndjson")
            expect(File.exist?(path)).to eq(true), "#{path} does not exist"
          end
        end
      end
    end
  end

  def exported_path_for(*file)
    File.join(group_tree_saver.full_path, 'groups', *file)
  end

  def setup_groups
    root = setup_group
    subgroup = setup_group(parent: root)
    setup_group(parent: subgroup)

    root
  end

  def setup_group(parent: nil)
    group = create(:group, description: 'description', parent: parent)
    create(:milestone, group: group)
    create(:group_badge, group: group)
    group_label = create(:group_label, group: group)
    board = create(:board, group: group, milestone_id: Milestone::Upcoming.id)
    create(:list, board: board, label: group_label)
    create(:group_badge, group: group)
    create(:label_priority, label: group_label, priority: 1)

    group
  end
end
