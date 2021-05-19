# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Policy::Changes do
  let_it_be(:project) { create(:project) }

  describe '#satisfied_by?' do
    describe 'paths matching' do
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
          %w[some/modified/ruby/file.rb some/other_file.txt some/.dir/file]
        end
      end

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

      it 'is satisfied by matching a pattern with a dot' do
        policy = described_class.new(%w[some/*/file])

        expect(policy).to be_satisfied_by(pipeline, seed)
      end

      it 'is satisfied by matching a pattern with a glob' do
        policy = described_class.new(%w[some/**/*.{rb,txt}])

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

      it 'is not satified when pattern with glob does not match' do
        policy = described_class.new(%w[invalid/*.{md,rake}])

        expect(policy).not_to be_satisfied_by(pipeline, seed)
      end

      context 'when modified paths can not be evaluated' do
        before do
          allow(pipeline).to receive(:modified_paths) { nil }
        end

        it 'is always satisfied' do
          policy = described_class.new(%w[invalid/*])

          expect(policy).to be_satisfied_by(pipeline, seed)
        end
      end
    end

    describe 'gitaly integration' do
      let_it_be(:project) { create(:project, :repository) }

      let(:pipeline) do
        create(:ci_empty_pipeline, project: project,
                                   ref: 'master',
                                   source: :push,
                                   sha: '498214d',
                                   before_sha: '281d3a7')
      end

      let(:build) do
        create(:ci_build, pipeline: pipeline, project: project, ref: 'master')
      end

      let(:seed) { double('build seed', to_resource: build) }

      it 'is satisfied by changes introduced by a push' do
        policy = described_class.new(['with space/*.md'])

        expect(policy).to be_satisfied_by(pipeline, seed)
      end

      it 'is not satisfied by changes that are not in the push' do
        policy = described_class.new(%w[files/js/commit.js])

        expect(policy).not_to be_satisfied_by(pipeline, seed)
      end
    end

    context 'when branch is created' do
      let_it_be(:project) { create(:project, :repository) }

      let(:pipeline) do
        create(:ci_empty_pipeline, project: project,
                                   ref: 'feature',
                                   source: source,
                                   sha: '0b4bc9a4',
                                   before_sha: Gitlab::Git::BLANK_SHA,
                                   merge_request: merge_request)
      end

      let(:ci_build) do
        build(:ci_build, pipeline: pipeline, project: project, ref: 'feature')
      end

      let(:seed) { double('build seed', to_resource: ci_build) }

      context 'when source is merge request' do
        let(:source) { :merge_request_event }

        let(:merge_request) do
          create(:merge_request,
                 source_project: project,
                 source_branch: 'feature',
                 target_project: project,
                 target_branch: 'master')
        end

        it 'is satified by changes in the merge request' do
          policy = described_class.new(%w[files/ruby/feature.rb])

          expect(policy).to be_satisfied_by(pipeline, seed)
        end

        it 'is not satified by changes not in the merge request' do
          policy = described_class.new(%w[foo.rb])

          expect(policy).not_to be_satisfied_by(pipeline, seed)
        end
      end

      context 'when source is push' do
        let(:source) { :push }
        let(:merge_request) { nil }

        it 'is always satified' do
          policy = described_class.new(%w[foo.rb])

          expect(policy).to be_satisfied_by(pipeline, seed)
        end
      end
    end
  end
end
