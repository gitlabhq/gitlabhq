# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::RelationRenameService do
  include ImportExport::CommonUtil

  let(:renames) do
    {
      'example_relation1' => 'new_example_relation1',
      'example_relation2' => 'new_example_relation2'
    }
  end

  let(:user) { create(:admin) }
  let(:group) { create(:group, :nested) }
  let!(:project) { create(:project, :builds_disabled, :issues_disabled, group: group, name: 'project', path: 'project') }
  let(:shared) { project.import_export_shared }

  before do
    stub_const("#{described_class}::RENAMES", renames)
  end

  context 'when importing' do
    let(:project_tree_restorer) { Gitlab::ImportExport::ProjectTreeRestorer.new(user: user, shared: shared, project: project) }
    let(:file_content) { IO.read(File.join(shared.export_path, 'project.json')) }
    let(:json_file) { ActiveSupport::JSON.decode(file_content) }

    before do
      setup_import_export_config('complex')

      allow(ActiveSupport::JSON).to receive(:decode).and_call_original
      allow(ActiveSupport::JSON).to receive(:decode).with(file_content).and_return(json_file)
    end

    context 'when the file has only old relationship names' do
      # Configuring the json as an old version exported file, with only
      # the previous association with the old name
      before do
        renames.each do |old_name, _|
          json_file[old_name.to_s] = []
        end
      end

      it 'renames old relationships to the new name' do
        expect(json_file.keys).to include(*renames.keys)

        project_tree_restorer.restore

        expect(json_file.keys).to include(*renames.values)
        expect(json_file.keys).not_to include(*renames.keys)
      end
    end

    context 'when the file has both the old and new relationships' do
      # Configuring the json as the new version exported file, with both
      # the old association name and the new one
      before do
        renames.each do |old_name, new_name|
          json_file[old_name.to_s] = [1]
          json_file[new_name.to_s] = [2]
        end
      end

      it 'uses the new relationships and removes the old ones from the hash' do
        expect(json_file.keys).to include(*renames.keys)

        project_tree_restorer.restore

        expect(json_file.keys).to include(*renames.values)
        expect(json_file.values_at(*renames.values).flatten.uniq.first).to eq 2
        expect(json_file.keys).not_to include(*renames.keys)
      end
    end

    context 'when the file has only new relationship names' do
      # Configuring the json as the future version exported file, with only
      # the new association name
      before do
        renames.each do |_, new_name|
          json_file[new_name.to_s] = []
        end
      end

      it 'uses the new relationships' do
        expect(json_file.keys).not_to include(*renames.keys)

        project_tree_restorer.restore

        expect(json_file.keys).to include(*renames.values)
      end
    end
  end

  context 'when exporting' do
    let(:export_content_path) { project_tree_saver.full_path }
    let(:export_content_hash) { ActiveSupport::JSON.decode(File.read(export_content_path)) }
    let(:injected_hash) { renames.values.product([{}]).to_h }
    let(:relation_tree_saver) { Gitlab::ImportExport::RelationTreeSaver.new }

    let(:project_tree_saver) do
      Gitlab::ImportExport::ProjectTreeSaver.new(
        project: project, current_user: user, shared: shared)
    end

    before do
      allow(project_tree_saver).to receive(:tree_saver).and_return(relation_tree_saver)
    end

    it 'adds old relationships to the exported file' do
      # we inject relations with new names that should be rewritten
      expect(relation_tree_saver).to receive(:serialize).and_wrap_original do |method, *args|
        method.call(*args).merge(injected_hash)
      end

      expect(project_tree_saver.save).to eq(true)

      expect(export_content_hash.keys).to include(*renames.keys)
      expect(export_content_hash.keys).to include(*renames.values)
    end
  end
end
