require 'spec_helper'

describe Gitlab::GithubImport::Importer::LabelLinksImporter do
  let(:project) { create(:project) }
  let(:client) { double(:client) }
  let(:issue) do
    double(
      :issue,
      iid: 4,
      label_names: %w[bug],
      issuable_type: Issue,
      pull_request?: false
    )
  end

  let(:importer) { described_class.new(issue, project, client) }

  describe '#execute' do
    it 'creates the label links' do
      importer = described_class.new(issue, project, client)

      expect(importer).to receive(:create_labels)

      importer.execute
    end
  end

  describe '#create_labels' do
    it 'inserts the label links in bulk' do
      expect(importer.label_finder)
        .to receive(:id_for)
        .with('bug')
        .and_return(2)

      expect(importer)
        .to receive(:find_target_id)
        .and_return(1)

      Timecop.freeze do
        expect(Gitlab::Database)
          .to receive(:bulk_insert)
          .with(
            LabelLink.table_name,
            [
              {
                label_id: 2,
                target_id: 1,
                target_type: Issue,
                created_at: Time.zone.now,
                updated_at: Time.zone.now
              }
            ]
          )

        importer.create_labels
      end
    end

    it 'does not insert label links for non-existing labels' do
      expect(importer.label_finder)
        .to receive(:id_for)
        .with('bug')
        .and_return(nil)

      expect(Gitlab::Database)
        .to receive(:bulk_insert)
        .with(LabelLink.table_name, [])

      importer.create_labels
    end
  end

  describe '#find_target_id' do
    it 'returns the ID of the issuable to create the label link for' do
      expect_any_instance_of(Gitlab::GithubImport::IssuableFinder)
        .to receive(:database_id)
        .and_return(10)

      expect(importer.find_target_id).to eq(10)
    end
  end
end
