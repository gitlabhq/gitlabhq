require 'spec_helper'

describe CommitCollection do
  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit }

  describe '#each' do
    it 'yields every commit' do
      collection = described_class.new(project, [commit])

      expect { |b| collection.each(&b) }.to yield_with_args(commit)
    end
  end

  describe '#with_pipeline_status' do
    it 'sets the pipeline status for every commit so no additional queries are necessary' do
      create(
        :ci_empty_pipeline,
        ref: 'master',
        sha: commit.id,
        status: 'success',
        project: project
      )

      collection = described_class.new(project, [commit])
      collection.with_pipeline_status

      recorder = ActiveRecord::QueryRecorder.new do
        expect(commit.status).to eq('success')
      end

      expect(recorder.count).to be_zero
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true when the underlying Array responds to the message' do
      collection = described_class.new(project, [])

      expect(collection.respond_to?(:last)).to eq(true)
    end

    it 'returns false when the underlying Array does not respond to the message' do
      collection = described_class.new(project, [])

      expect(collection.respond_to?(:foo)).to eq(false)
    end
  end

  describe '#method_missing' do
    it 'delegates undefined methods to the underlying Array' do
      collection = described_class.new(project, [commit])

      expect(collection.length).to eq(1)
      expect(collection.last).to eq(commit)
      expect(collection).not_to be_empty
    end
  end
end
