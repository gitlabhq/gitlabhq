# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::MilestonesImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:project) { create(:project, import_source: 'foo/bar') }
  let(:client) { double(:client) }
  let(:importer) { described_class.new(project, client) }
  let(:due_on) { Time.new(2017, 2, 1, 12, 00) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }

  let(:milestone) do
    {
      number: 1,
      title: '1.0',
      description: 'The first release',
      state: 'open',
      due_on: due_on,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  let(:milestone2) do
    {
      number: 1,
      title: '1.0',
      description: 'The first release',
      state: 'open',
      due_on: nil,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  describe '#execute' do
    it 'imports the milestones in bulk' do
      milestone_hash = { number: 1, title: '1.0' }

      expect(importer).to receive(:build_milestones).and_return([[milestone_hash], []])
      expect(importer).to receive(:bulk_insert).with([milestone_hash])
      expect(importer).to receive(:build_milestones_cache)

      importer.execute
    end
  end

  describe '#build_milestones' do
    it 'returns an Array containing milestone rows' do
      expect(importer)
        .to receive(:each_milestone)
        .and_return([milestone])

      rows, errors = importer.build_milestones

      expect(rows.length).to eq(1)
      expect(rows[0][:title]).to eq('1.0')
      expect(errors).to be_empty
    end

    it 'does not build milestones that already exist' do
      create(:milestone, project: project, title: '1.0', iid: 1)

      expect(importer)
        .to receive(:each_milestone)
        .and_return([milestone])

      rows, errors = importer.build_milestones

      expect(rows).to be_empty
      expect(errors).to be_empty
    end

    it 'does not build milestones that are invalid' do
      milestone = { id: 123456, title: nil, number: 2 }

      expect(importer)
        .to receive(:each_milestone)
        .and_return([milestone])

      expect(Gitlab::GithubImport::Logger).to receive(:error)
        .with(
          project_id: project.id,
          importer: described_class.name,
          message: ["Title can't be blank"],
          external_identifiers: { iid: 2, object_type: :milestone, title: nil }
        )

      rows, errors = importer.build_milestones

      expect(rows).to be_empty
      expect(errors.length).to eq(1)
      expect(errors[0][:validation_errors].full_messages).to match_array(["Title can't be blank"])
    end
  end

  describe '#build_milestones_cache' do
    it 'builds the milestones cache' do
      expect_next_instance_of(Gitlab::GithubImport::MilestoneFinder) do |instance|
        expect(instance).to receive(:build_cache)
      end

      importer.build_milestones_cache
    end
  end

  describe '#build_attributes' do
    let(:milestone_hash) { importer.build_attributes(milestone) }
    let(:milestone_hash2) { importer.build_attributes(milestone2) }

    it 'returns the attributes of the milestone as a Hash' do
      expect(milestone_hash).to be_an_instance_of(Hash)
    end

    context 'the returned Hash' do
      it 'includes the milestone number' do
        expect(milestone_hash[:iid]).to eq(1)
      end

      it 'includes the milestone title' do
        expect(milestone_hash[:title]).to eq('1.0')
      end

      it 'includes the milestone description' do
        expect(milestone_hash[:description]).to eq('The first release')
      end

      it 'includes the project ID' do
        expect(milestone_hash[:project_id]).to eq(project.id)
      end

      it 'includes the milestone state' do
        expect(milestone_hash[:state]).to eq(:active)
      end

      it 'includes the due date' do
        expect(milestone_hash[:due_date]).to eq(due_on.to_date)
      end

      it 'responds correctly to no due date value' do
        expect(milestone_hash2[:due_date]).to be nil
      end

      it 'includes the created timestamp' do
        expect(milestone_hash[:created_at]).to eq(created_at)
      end

      it 'includes the updated timestamp' do
        expect(milestone_hash[:updated_at]).to eq(updated_at)
      end
    end
  end

  describe '#each_milestone' do
    it 'returns the milestones' do
      expect(client)
        .to receive(:milestones)
        .with('foo/bar', state: 'all')

      importer.each_milestone
    end
  end
end
