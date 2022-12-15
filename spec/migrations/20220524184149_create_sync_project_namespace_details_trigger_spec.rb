# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe CreateSyncProjectNamespaceDetailsTrigger, feature_category: :projects do
  let(:migration) { described_class.new }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_details) { table(:namespace_details) }
  let!(:timestamp) { Time.new(2020, 01, 01).utc }
  let!(:project_namespace) { namespaces.create!(name: 'name', path: 'path') }
  let!(:namespace) { namespaces.create!(name: 'group', path: 'group_path') }

  let(:synced_attributes) do
    {
      description: 'description',
      description_html: '<p>description</p>',
      cached_markdown_version: 1966080,
      updated_at: timestamp
    }
  end

  let(:other_attributes) do
    {
      name: 'project_name',
      project_namespace_id: project_namespace.id,
      namespace_id: namespace.id
    }
  end

  let(:attributes) { other_attributes.merge(synced_attributes) }

  describe '#up' do
    before do
      migrate!
    end

    describe 'INSERT trigger' do
      it 'the created namespace_details record has matching attributes' do
        project = projects.create!(attributes)
        synced_namespace_details = namespace_details.find_by(namespace_id: project.project_namespace_id)

        expect(synced_namespace_details).to have_attributes(synced_attributes)
      end
    end

    describe 'UPDATE trigger' do
      let!(:project) { projects.create!(attributes) }

      it 'updates the attribute in the synced namespace_details record' do
        project.update!(description: 'new_description')

        synced_namespace_details = namespace_details.find_by(namespace_id: project.project_namespace_id)
        expect(synced_namespace_details.description).to eq('new_description')
      end
    end
  end

  describe '#down' do
    before do
      migration.up
      migration.down
    end

    it 'drops the trigger' do
      expect do
        projects.create!(attributes)
      end.not_to change(namespace_details, :count)
    end
  end
end
