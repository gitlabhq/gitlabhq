require 'spec_helper'

describe Gitlab::GithubImport::BulkImporting do
  let(:importer) do
    Class.new { include(Gitlab::GithubImport::BulkImporting) }.new
  end

  describe '#build_database_rows' do
    it 'returns an Array containing the rows to insert' do
      object = double(:object, title: 'Foo')

      expect(importer)
        .to receive(:build)
        .with(object)
        .and_return({ title: 'Foo' })

      expect(importer)
        .to receive(:already_imported?)
        .with(object)
        .and_return(false)

      enum = [[object, 1]].to_enum

      expect(importer.build_database_rows(enum)).to eq([{ title: 'Foo' }])
    end

    it 'does not import objects that have already been imported' do
      object = double(:object, title: 'Foo')

      expect(importer)
        .not_to receive(:build)

      expect(importer)
        .to receive(:already_imported?)
        .with(object)
        .and_return(true)

      enum = [[object, 1]].to_enum

      expect(importer.build_database_rows(enum)).to be_empty
    end
  end

  describe '#bulk_insert' do
    it 'bulk inserts rows into the database' do
      rows = [{ title: 'Foo' }] * 10
      model = double(:model, table_name: 'kittens')

      expect(Gitlab::Database)
        .to receive(:bulk_insert)
        .ordered
        .with('kittens', rows.first(5))

      expect(Gitlab::Database)
        .to receive(:bulk_insert)
        .ordered
        .with('kittens', rows.last(5))

      importer.bulk_insert(model, rows, batch_size: 5)
    end
  end
end
