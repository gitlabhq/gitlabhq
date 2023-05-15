# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceDetails, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:namespace_details) { table(:namespace_details) }

  subject(:perform_migration) do
    described_class.new(
      start_id: namespaces.minimum(:id),
      end_id: namespaces.maximum(:id),
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  describe '#perform' do
    it 'creates details for all namespaces in range' do
      namespace1 = namespaces.create!(
        id: 5, name: 'test1', path: 'test1', description: "Some description1",
        description_html: "Some description html1", cached_markdown_version: 4
      )
      namespaces.create!(
        id: 6, name: 'test2', path: 'test2', type: 'Project',
        description: "Some description2", description_html: "Some description html2",
        cached_markdown_version: 4
      )
      namespace3 = namespaces.create!(
        id: 7, name: 'test3', path: 'test3', description: "Some description3",
        description_html: "Some description html3", cached_markdown_version: 4
      )
      namespace4 = namespaces.create!(
        id: 8, name: 'test4', path: 'test4', description: "Some description3",
        description_html: "Some description html4", cached_markdown_version: 4
      )
      namespace_details.delete_all

      expect(namespace_details.pluck(:namespace_id)).to eql []

      expect { perform_migration }
        .to change { namespace_details.pluck(:namespace_id) }.from([]).to contain_exactly(
          namespace1.id,
          namespace3.id,
          namespace4.id
        )

      expect(namespace_details.find_by_namespace_id(namespace1.id)).to have_attributes(migrated_attributes(namespace1))
      expect(namespace_details.find_by_namespace_id(namespace3.id)).to have_attributes(migrated_attributes(namespace3))
      expect(namespace_details.find_by_namespace_id(namespace4.id)).to have_attributes(migrated_attributes(namespace4))
    end
  end

  def migrated_attributes(namespace)
    {
      description: namespace.description,
      description_html: namespace.description_html,
      cached_markdown_version: namespace.cached_markdown_version
    }
  end
end
