# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceDetailsDescriptionFields, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_details) { table(:namespace_details) }
  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }

  subject(:perform_migration) do
    described_class.new(
      start_id: namespace_details.minimum(:namespace_id),
      end_id: namespace_details.maximum(:namespace_id),
      batch_table: :namespace_details,
      batch_column: :namespace_id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  describe '#perform' do
    context 'when namespace has description fields and namespace_details do not' do
      # these columns are added to ignore_columns :description, :description_html, :cached_markdown_version
      # need to manually populate these fields
      let!(:namespace1) do
        namespaces.create!(
          name: 'namespace-1',
          path: 'namespace-1',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:namespace_detail1) do
        namespace_details.insert({
          namespace_id: namespace1.id,
          description: nil,
          description_html: nil,
          cached_markdown_version: nil,
          created_at: Time.current,
          updated_at: Time.current
        })

        ApplicationRecord.connection.execute(<<~SQL)
          UPDATE namespaces
          SET description = 'Test description 1',
              description_html = '<p>Test description 1</p>',
              cached_markdown_version = 1
          WHERE id = #{namespace1.id}
        SQL
        namespace_details.find(namespace1.id)
      end

      let!(:namespace2) do
        namespaces.create!(
          name: 'namespace-2',
          path: 'namespace-2',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:namespace_detail2) do
        namespace_details.insert({
          namespace_id: namespace2.id,
          description: nil,
          description_html: nil,
          cached_markdown_version: nil,
          created_at: Time.current,
          updated_at: Time.current
        })
        ApplicationRecord.connection.execute(<<~SQL)
          UPDATE namespaces
          SET description = 'Test description 2',
              description_html = '<p>Test description 2</p>',
              cached_markdown_version = 3
          WHERE id = #{namespace2.id}
        SQL
        namespace_details.find(namespace2.id)
      end

      it 'backfills namespace_details with description fields from namespaces' do
        perform_migration

        detail1 = namespace_details.find(namespace1.id)
        detail2 = namespace_details.find(namespace2.id)

        expect(detail1.description).to eq('Test description 1')
        expect(detail1.description_html).to eq('<p>Test description 1</p>')
        expect(detail1.cached_markdown_version).to eq(1)

        expect(detail2.description).to eq('Test description 2')
        expect(detail2.description_html).to eq('<p>Test description 2</p>')
        expect(detail2.cached_markdown_version).to eq(3)
      end
    end

    context 'when namespace_details already have description fields' do
      let!(:namespace) do
        namespaces.create!(
          name: 'namespace-existing',
          path: 'namespace-existing',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:namespace_detail) do
        ApplicationRecord.connection.execute(<<~SQL)
          UPDATE namespaces
          SET description = 'New description',
              description_html = '<p>New description</p>',
              cached_markdown_version = 999999
          WHERE id = #{namespace.id}
        SQL

        ApplicationRecord.connection.execute(<<~SQL)
          UPDATE namespace_details
          SET description = 'Existing description',
              description_html = '<p>Existing description</p>',
              cached_markdown_version = 111111
          WHERE namespace_id = #{namespace.id}
        SQL
        namespace_details.find(namespace.id)
      end

      it 'does not overwrite existing namespace_details fields' do
        perform_migration

        detail = namespace_details.find(namespace.id)

        expect(detail.description).to eq('Existing description')
        expect(detail.description_html).to eq('<p>Existing description</p>')
        expect(detail.cached_markdown_version).to eq(111111)
      end
    end

    context 'when namespace_details has partial fields' do
      let!(:namespace) do
        namespaces.create!(
          name: 'namespace-partial-details',
          path: 'namespace-partial-details',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:namespace_detail) do
        ApplicationRecord.connection.execute(<<~SQL)
          UPDATE namespaces
          SET description = 'Updated description',
              description_html = '<p>Updated description</p>',
              cached_markdown_version = 777777
          WHERE id = #{namespace.id}
        SQL

        ApplicationRecord.connection.execute(<<~SQL)
          UPDATE namespace_details
          SET description = 'Existing description',
              description_html = NULL,
              cached_markdown_version = NULL
          WHERE namespace_id = #{namespace.id}
        SQL
        namespace_details.find(namespace.id)
      end

      it 'only backfills the null fields' do
        perform_migration

        detail = namespace_details.find(namespace.id)

        expect(detail.description).to eq('Existing description')
        expect(detail.description_html).to eq('<p>Updated description</p>')
        expect(detail.cached_markdown_version).to eq(777777)
      end
    end
  end
end
