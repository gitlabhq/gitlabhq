require 'spec_helper'

describe Gitlab::Ci::Build::Policy::Changes do
  set(:project) { create(:project) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project,
                              ref: 'master',
                              source: :push,
                              sha: '1234abcd',
                              before_sha: '0123aabb')
  end

  let(:ci_build) do
    build(:ci_build, pipeline: pipeline, project: project, ref: 'master')
  end

  let(:seed) { double('build seed', to_resource: ci_build) }

  before do
    allow(pipeline).to receive(:modified_paths) do
      %w[some/modified/ruby/file.rb some/other_file.txt]
    end
  end

  describe '#satisfied_by?' do
    it 'is satisfied by matching literal path' do
      policy = described_class.new(%w[some/other_file.txt])

      expect(policy).to be_satisfied_by(pipeline, seed)
    end

    it 'is satisfied by matching simple pattern' do
      policy = described_class.new(%w[some/*.txt])

      expect(policy).to be_satisfied_by(pipeline, seed)
    end

    it 'is satisfied by matching recusive pattern' do
      policy = described_class.new(%w[some/**/*.rb])

      expect(policy).to be_satisfied_by(pipeline, seed)
    end

    it 'is not satisfied when pattern does not match path' do
      policy = described_class.new(%w[some/*.rb])

      expect(policy).not_to be_satisfied_by(pipeline, seed)
    end

    it 'is not satisfied when pattern does not match' do
      policy = described_class.new(%w[invalid/*.md])

      expect(policy).not_to be_satisfied_by(pipeline, seed)
    end

    context 'when pipelines does not run for a branch update' do
      before do
        pipeline.before_sha = Gitlab::Git::BLANK_SHA
      end

      it 'is always satisfied' do
        policy = described_class.new(%w[invalid/*])

        expect(policy).to be_satisfied_by(pipeline, seed)
      end
    end
  end
end
