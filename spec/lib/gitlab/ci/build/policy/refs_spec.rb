# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Build::Policy::Refs do
  describe '#satisfied_by?' do
    context 'when matching ref' do
      let(:pipeline) { build_stubbed(:ci_pipeline, ref: 'master') }

      it 'is satisfied when pipeline branch matches' do
        expect(described_class.new(%w[master deploy]))
          .to be_satisfied_by(pipeline)
      end

      it 'is not satisfied when pipeline branch does not match' do
        expect(described_class.new(%w[feature fix]))
          .not_to be_satisfied_by(pipeline)
      end
    end

    context 'when matching tags' do
      context 'when pipeline runs for a tag' do
        let(:pipeline) do
          build_stubbed(:ci_pipeline, ref: 'feature', tag: true)
        end

        it 'is satisfied when tags matcher is specified' do
          expect(described_class.new(%w[master tags]))
            .to be_satisfied_by(pipeline)
        end
      end

      context 'when pipeline is not created for a tag' do
        let(:pipeline) do
          build_stubbed(:ci_pipeline, ref: 'feature', tag: false)
        end

        it 'is not satisfied when tag match is specified' do
          expect(described_class.new(%w[master tags]))
            .not_to be_satisfied_by(pipeline)
        end
      end
    end

    context 'when also matching a path' do
      let(:pipeline) do
        build_stubbed(:ci_pipeline, ref: 'master')
      end

      it 'is satisfied when provided patch matches specified one' do
        expect(described_class.new(%W[master@#{pipeline.project_full_path}]))
          .to be_satisfied_by(pipeline)
      end

      it 'is not satisfied when path differs' do
        expect(described_class.new(%w[master@some/fork/repository]))
          .not_to be_satisfied_by(pipeline)
      end
    end

    context 'when matching a source' do
      let(:pipeline) { build_stubbed(:ci_pipeline, source: :push) }

      it 'is satisfied when provided source keyword matches' do
        expect(described_class.new(%w[pushes]))
          .to be_satisfied_by(pipeline)
      end

      it 'is not satisfied when provided source keyword does not match' do
        expect(described_class.new(%w[triggers]))
          .not_to be_satisfied_by(pipeline)
      end

      context 'when source is merge_request_event' do
        let(:pipeline) { build_stubbed(:ci_pipeline, source: :merge_request_event) }

        it 'is satisfied with only: merge_request' do
          expect(described_class.new(%w[merge_requests]))
            .to be_satisfied_by(pipeline)
        end

        it 'is not satisfied with only: merge_request_event' do
          expect(described_class.new(%w[merge_request_events]))
            .not_to be_satisfied_by(pipeline)
        end
      end

      context 'when source is external_pull_request_event' do
        let(:pipeline) { build_stubbed(:ci_pipeline, source: :external_pull_request_event) }

        it 'is satisfied with only: external_pull_request' do
          expect(described_class.new(%w[external_pull_requests]))
            .to be_satisfied_by(pipeline)
        end

        it 'is not satisfied with only: external_pull_request_event' do
          expect(described_class.new(%w[external_pull_request_events]))
            .not_to be_satisfied_by(pipeline)
        end
      end

      context 'when source is pipeline' do
        let(:pipeline) { build_stubbed(:ci_pipeline, source: :pipeline) }

        it 'is satisfied with only: pipelines' do
          expect(described_class.new(%w[pipelines]))
            .to be_satisfied_by(pipeline)
        end

        it 'is satisfied with only: pipeline' do
          expect(described_class.new(%w[pipeline]))
            .to be_satisfied_by(pipeline)
        end
      end

      context 'when source is parent_pipeline' do
        let(:pipeline) { build_stubbed(:ci_pipeline, source: :parent_pipeline) }

        it 'is satisfied with only: parent_pipelines' do
          expect(described_class.new(%w[parent_pipelines]))
            .to be_satisfied_by(pipeline)
        end

        it 'is satisfied with only: parent_pipeline' do
          expect(described_class.new(%w[parent_pipeline]))
            .to be_satisfied_by(pipeline)
        end
      end
    end

    context 'when matching a ref by a regular expression' do
      let(:pipeline) { build_stubbed(:ci_pipeline, ref: 'docs-something') }

      it 'is satisfied when regexp matches pipeline ref' do
        expect(described_class.new(['/docs-.*/']))
          .to be_satisfied_by(pipeline)
      end

      it 'is satisfied when case-insensitive regexp matches pipeline ref' do
        expect(described_class.new(['/DOCS-.*/i']))
          .to be_satisfied_by(pipeline)
      end

      it 'is not satisfied when regexp does not match pipeline ref' do
        expect(described_class.new(['/fix-.*/']))
          .not_to be_satisfied_by(pipeline)
      end

      context 'when unsafe regexp is used' do
        let(:subject) { described_class.new(['/^(?!master).+/']) }

        context 'when allow_unsafe_ruby_regexp is disabled' do
          before do
            stub_feature_flags(allow_unsafe_ruby_regexp: false)
          end

          it 'ignores invalid regexp' do
            expect(subject)
              .not_to be_satisfied_by(pipeline)
          end
        end

        context 'when allow_unsafe_ruby_regexp is enabled' do
          before do
            stub_feature_flags(allow_unsafe_ruby_regexp: true)
          end

          it 'is satisfied by regexp' do
            expect(subject)
              .to be_satisfied_by(pipeline)
          end
        end
      end
    end

    context 'malicious regexp' do
      let(:pipeline) { build_stubbed(:ci_pipeline, ref: malicious_text) }

      subject { described_class.new([malicious_regexp_ruby]) }

      include_examples 'malicious regexp'
    end
  end
end
