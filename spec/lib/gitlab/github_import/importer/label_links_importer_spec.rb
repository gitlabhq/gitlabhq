# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::LabelLinksImporter, feature_category: :importers do
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
        .and_return(4)

      expect(LabelLink).to receive(:bulk_insert!)

      importer.create_labels
    end

    it 'does not insert label links for non-existing labels' do
      expect(importer)
        .to receive(:find_target_id)
        .and_return(4)

      expect(importer.label_finder)
        .to receive(:id_for)
        .with('bug')
        .and_return(nil)

      expect(LabelLink)
        .to receive(:bulk_insert!)
        .with([])

      importer.create_labels
    end

    it 'does not insert label links for non-existing targets' do
      expect(importer)
        .to receive(:find_target_id)
        .and_return(nil)

      expect(importer.label_finder)
        .not_to receive(:id_for)

      expect(LabelLink)
        .not_to receive(:bulk_insert!)

      importer.create_labels
    end
  end

  describe '#find_target_id' do
    it 'returns the ID of the issuable to create the label link for' do
      expect_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |instance|
        expect(instance).to receive(:database_id).and_return(10)
      end

      expect(importer.find_target_id).to eq(10)
    end
  end
end
