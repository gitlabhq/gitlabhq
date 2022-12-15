# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe CreateSyncNamespaceDetailsTrigger, feature_category: :subgroups do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_details) { table(:namespace_details) }
  let!(:timestamp) { Time.new(2020, 01, 01).utc }

  let(:synced_attributes) do
    {
      description: 'description',
      description_html: '<p>description</p>',
      cached_markdown_version: 1966080,
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  let(:other_attributes) do
    {
      name: 'name',
      path: 'path'
    }
  end

  let(:attributes) { other_attributes.merge(synced_attributes) }

  describe '#up' do
    before do
      migrate!
    end

    describe 'INSERT trigger' do
      it 'creates a namespace_detail record' do
        expect do
          namespaces.create!(attributes)
        end.to change(namespace_details, :count).by(1)
      end

      it 'the created namespace_details record has matching attributes' do
        namespaces.create!(attributes)
        synced_namespace_details = namespace_details.last

        expect(synced_namespace_details).to have_attributes(synced_attributes)
      end
    end

    describe 'UPDATE trigger' do
      let!(:namespace) { namespaces.create!(attributes) }

      it 'updates the attribute in the synced namespace_details record' do
        namespace.update!(description: 'new_description')

        synced_namespace_details = namespace_details.last
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
        namespaces.create!(attributes)
      end.not_to change(namespace_details, :count)
    end
  end
end
