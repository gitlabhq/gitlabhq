# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::LabelLinksImporter, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:persisted_issue) { create(:issue, project: project) }
  let_it_be(:persisted_label) { create(:label, project: project) }
  let(:deleted_label) { create(:label, project: project) }
  let(:client) { double(:client) }
  let(:issue) do
    double(
      :issue,
      iid: 4,
      label_names: %w[bug non_existent_label],
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
    context 'when items are valid' do
      before do
        allow(importer.label_finder)
          .to receive(:id_for)
          .with('bug')
          .and_return(persisted_label.id)
        allow(importer.label_finder)
          .to receive(:id_for)
          .with('non_existent_label')
          .and_return(deleted_label.id)
        allow(importer)
          .to receive(:find_target_id)
          .and_return(persisted_issue.id)
        deleted_label.destroy!
      end

      it 'inserts the label links in bulk, but only the valid ones', :aggregate_failures do
        expect(LabelLink).to receive(:bulk_insert!) do |*args, **kwargs|
          bulk_items = args.first
          expect(bulk_items).to contain_exactly(
            have_attributes(
              label_id: persisted_label.id,
              target_id: persisted_issue.id,
              namespace_id: persisted_issue.namespace_id
            )
          )
          expect(kwargs[:validate]).to be(false)
        end

        importer.create_labels
      end

      it 'tracks invalid label links' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).with(
          project_id: project.id,
          error_source: described_class.name,
          exception: instance_of(ActiveRecord::RecordInvalid),
          fail_import: false,
          external_identifiers: hash_including(
            label_id: deleted_label.id,
            target_id: persisted_issue.id,
            target_type: 'Issue',
            namespace_id: persisted_issue.namespace_id
          )
        )

        importer.create_labels
      end
    end

    it 'does not insert label links for non-existing labels' do
      expect(importer)
        .to receive(:find_target_id)
        .and_return(4)

      allow(importer.label_finder).to receive(:id_for)
      expect(importer.label_finder)
        .to receive(:id_for)
        .with('bug')
        .and_return(nil)

      expect(LabelLink)
        .to receive(:bulk_insert!)
        .with([], validate: false)

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
