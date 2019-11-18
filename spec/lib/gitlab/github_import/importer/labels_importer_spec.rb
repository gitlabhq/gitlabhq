# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Importer::LabelsImporter, :clean_gitlab_redis_cache do
  let(:project) { create(:project, import_source: 'foo/bar') }
  let(:client) { double(:client) }
  let(:importer) { described_class.new(project, client) }

  describe '#execute' do
    it 'imports the labels in bulk' do
      label_hash = { title: 'bug', color: '#fffaaa' }

      expect(importer)
        .to receive(:build_labels)
        .and_return([label_hash])

      expect(importer)
        .to receive(:bulk_insert)
        .with(Label, [label_hash])

      expect(importer)
        .to receive(:build_labels_cache)

      importer.execute
    end
  end

  describe '#build_labels' do
    it 'returns an Array containnig label rows' do
      label = double(:label, name: 'bug', color: 'ffffff')

      expect(importer).to receive(:each_label).and_return([label])

      rows = importer.build_labels

      expect(rows.length).to eq(1)
      expect(rows[0][:title]).to eq('bug')
    end

    it 'does not create labels that already exist' do
      create(:label, project: project, title: 'bug')

      label = double(:label, name: 'bug', color: 'ffffff')

      expect(importer).to receive(:each_label).and_return([label])
      expect(importer.build_labels).to be_empty
    end
  end

  describe '#build_labels_cache' do
    it 'builds the labels cache' do
      expect_any_instance_of(Gitlab::GithubImport::LabelFinder)
        .to receive(:build_cache)

      importer.build_labels_cache
    end
  end

  describe '#build' do
    let(:label_hash) do
      importer.build(double(:label, name: 'bug', color: 'ffffff'))
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
        Timecop.freeze do
          expect(label_hash[:created_at]).to eq(Time.zone.now)
        end
      end

      it 'includes the updated timestamp' do
        Timecop.freeze do
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
