# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::RelationSaver do
  include ImportExport::CommonUtil

  subject(:relation_saver) do
    described_class.new(project: project, shared: shared, relation: relation, user: user, params: params)
  end

  let_it_be(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { setup_project }
  let(:params) { { description: 'An overridden description' } }

  let(:relation) { Projects::ImportExport::RelationExport::ROOT_RELATION }
  let(:shared) do
    shared = project.import_export_shared
    allow(shared).to receive(:export_path).and_return(export_path)
    shared
  end

  after do
    FileUtils.rm_rf(export_path)
  end

  describe '#save' do
    it 'uses the ImportExport presenter' do
      expect(project).to receive(:present).with(
        presenter_class: Projects::ImportExport::ProjectExportPresenter,
        current_user: user,
        override_description: params[:description]
      )

      relation_saver.save # rubocop:disable Rails/SaveBang -- Call RelationSaver's #save, not ActiveRecord
    end

    context 'when relation is the root node' do
      let(:relation) { Projects::ImportExport::RelationExport::ROOT_RELATION }

      it 'serializes the root node as a json file in the export path' do
        relation_saver.save # rubocop:disable Rails/SaveBang

        json = read_json(File.join(shared.export_path, 'tree', 'project.json'))
        expect(json).to include({ 'description' => params[:description] })
      end

      it 'serializes only allowed attributes' do
        relation_saver.save # rubocop:disable Rails/SaveBang

        json = read_json(File.join(shared.export_path, 'tree', 'project.json'))
        expect(json).to include({ 'description' => params[:description] })
        expect(json.keys).not_to include('name')
      end

      it 'successfully serializes without errors' do
        result = relation_saver.save

        expect(result).to eq(true)
        expect(shared.errors).to be_empty
      end
    end

    context 'when relation is a child node' do
      let(:relation) { 'labels' }

      it 'serializes the child node as a ndjson file in the export path inside the project folder' do
        relation_saver.save # rubocop:disable Rails/SaveBang

        ndjson = read_ndjson(File.join(shared.export_path, 'tree', 'project', "#{relation}.ndjson"))
        expect(ndjson.first).to include({ 'title' => 'Label 1' })
        expect(ndjson.second).to include({ 'title' => 'Label 2' })
      end

      it 'serializes only allowed attributes' do
        relation_saver.save # rubocop:disable Rails/SaveBang

        ndjson = read_ndjson(File.join(shared.export_path, 'tree', 'project', "#{relation}.ndjson"))
        expect(ndjson.first.keys).not_to include('description_html')
      end

      it 'successfully serializes without errors' do
        result = relation_saver.save

        expect(result).to eq(true)
        expect(shared.errors).to be_empty
      end
    end

    context 'when relation name is not supported' do
      let(:relation) { 'unknown' }

      it 'returns false and register the error' do
        result = relation_saver.save

        expect(result).to eq(false)
        expect(shared.errors).to be_present
      end
    end

    context 'when an exception occurs during serialization' do
      it 'returns false and register the exception error message' do
        allow_next_instance_of(Gitlab::ImportExport::Json::StreamingSerializer) do |serializer|
          allow(serializer).to receive(:serialize_root).and_raise('Error!')
        end

        result = relation_saver.save

        expect(result).to eq(false)
        expect(shared.errors).to include('Error!')
      end
    end
  end

  def setup_project
    project = create(:project,
      description: 'Project description'
    )

    create(:label, project: project, title: 'Label 1')
    create(:label, project: project, title: 'Label 2')

    project
  end

  def read_json(path)
    Gitlab::Json.parse(File.read(path))
  end

  def read_ndjson(path)
    relations = []
    File.foreach(path) do |line|
      json = Gitlab::Json.parse(line)
      relations << json
    end
    relations
  end
end
