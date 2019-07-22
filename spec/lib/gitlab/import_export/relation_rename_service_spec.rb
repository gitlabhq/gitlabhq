# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::RelationRenameService do
  let(:renames) do
    {
      'example_relation1' => 'new_example_relation1',
      'example_relation2' => 'new_example_relation2'
    }
  end

  let(:user) { create(:admin) }
  let(:group) { create(:group, :nested) }
  let!(:project) { create(:project, :builds_disabled, :issues_disabled, name: 'project', path: 'project') }
  let(:shared) { project.import_export_shared }

  before do
    stub_const("#{described_class}::RENAMES", renames)
  end

  context 'when importing' do
    let(:project_tree_restorer) { Gitlab::ImportExport::ProjectTreeRestorer.new(user: user, shared: shared, project: project) }
    let(:import_path) { 'spec/lib/gitlab/import_export' }
    let(:file_content) { IO.read("#{import_path}/project.json") }
    let!(:json_file) { ActiveSupport::JSON.decode(file_content) }
    let(:tree_hash) { project_tree_restorer.instance_variable_get(:@tree_hash) }

    before do
      allow(shared).to receive(:export_path).and_return(import_path)
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
    let(:project_tree_saver) { Gitlab::ImportExport::ProjectTreeSaver.new(project: project, current_user: user, shared: shared) }
    let(:project_tree) { project_tree_saver.send(:project_json) }

    it 'adds old relationships to the exported file' do
      project_tree.merge!(renames.values.map { |new_name| [new_name, []] }.to_h)

      allow(project_tree_saver).to receive(:save) do |arg|
        project_tree_saver.send(:project_json_tree)
      end

      result = project_tree_saver.save

      saved_data = ActiveSupport::JSON.decode(result)

      expect(saved_data.keys).to include(*(renames.keys + renames.values))
    end
  end
end
