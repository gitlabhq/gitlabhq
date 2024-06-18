# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::LabelsImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:project) { create(:project, import_source: 'foo/bar') }
  let(:client) { double(:client) }
  let(:importer) { described_class.new(project, client) }

  describe '#execute' do
    it 'imports the labels in bulk' do
      label_hash = { title: 'bug', color: '#fffaaa' }

      expect(importer).to receive(:build_labels).and_return([[label_hash], []])
      expect(importer).to receive(:bulk_insert).with([label_hash])
      expect(importer).to receive(:build_labels_cache)

      importer.execute
    end
  end

  describe '#build_labels' do
    it 'returns an Array containing label rows' do
      label = { name: 'bug', color: 'ffffff' }

      expect(importer).to receive(:each_label).and_return([label])

      rows, errors = importer.build_labels

      expect(rows.length).to eq(1)
      expect(rows[0][:title]).to eq('bug')
      expect(errors).to be_blank
    end

    it 'does not build labels that already exist' do
      create(:label, project: project, title: 'bug')

      label = { name: 'bug', color: 'ffffff' }

      expect(importer).to receive(:each_label).and_return([label])

      rows, errors = importer.build_labels

      expect(rows).to be_empty
      expect(errors).to be_empty
    end

    it 'does not build labels that are invalid' do
      label = { id: 1, name: 'bug,bug', color: 'ffffff' }

      expect(importer).to receive(:each_label).and_return([label])
      expect(Gitlab::GithubImport::Logger).to receive(:error)
        .with(
          project_id: project.id,
          importer: described_class.name,
          message: ['Title is invalid'],
          external_identifiers: { title: 'bug,bug', object_type: :label }
        )

      rows, errors = importer.build_labels

      expect(rows).to be_empty
      expect(errors.length).to eq(1)
      expect(errors[0][:validation_errors].full_messages).to match_array(['Title is invalid'])
    end
  end

  describe '#build_labels_cache' do
    it 'builds the labels cache' do
      expect_next_instance_of(Gitlab::GithubImport::LabelFinder) do |instance|
        expect(instance).to receive(:build_cache)
      end

      importer.build_labels_cache
    end
  end

  describe '#build_attributes' do
    let(:label_hash) do
      importer.build_attributes({ name: 'bug', color: 'ffffff' })
    end

    it 'returns the attributes of the label as a Hash' do
      expect(label_hash).to be_an_instance_of(Hash)
    end

    context 'the returned Hash' do
      it 'includes the label title' do
        expect(label_hash[:title]).to eq('bug')
      end

      it 'includes the label color' do
        expect(label_hash[:color]).to eq('#ffffff')
      end

      it 'includes the project ID' do
        expect(label_hash[:project_id]).to eq(project.id)
      end

      it 'includes the label type' do
        expect(label_hash[:type]).to eq('ProjectLabel')
      end

      it 'includes the created timestamp' do
        freeze_time do
          expect(label_hash[:created_at]).to eq(Time.zone.now)
        end
      end

      it 'includes the updated timestamp' do
        freeze_time do
          expect(label_hash[:updated_at]).to eq(Time.zone.now)
        end
      end
    end
  end

  describe '#each_label' do
    it 'returns the labels' do
      expect(client)
        .to receive(:labels)
        .with('foo/bar')

      importer.each_label
    end
  end
end
