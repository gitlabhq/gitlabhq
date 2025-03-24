# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Step, feature_category: :continuous_integration do
  describe '#from_commands' do
    subject { described_class.from_commands(job) }

    before do
      job.run!
    end

    shared_examples 'has correct script' do
      it 'fabricates an object' do
        expect(subject.name).to eq(:script)
        expect(subject.script).to eq(script)
        expect(subject.when).to eq('on_success')
        expect(subject.allow_failure).to be_falsey
      end
    end

    context 'when script option is specified' do
      let(:job) { create(:ci_build, :no_options, options: { script: ["ls -la\necho aaa", "date"] }) }
      let(:script) { ["ls -la\necho aaa", 'date'] }

      it_behaves_like 'has correct script'
    end

    context 'when before and script option is specified' do
      let(:job) do
        create(:ci_build, options: {
          before_script: ["ls -la\necho aaa"],
          script: ["date"]
        })
      end

      let(:script) { ["ls -la\necho aaa", 'date'] }

      it_behaves_like 'has correct script'
    end

    context 'when timeout option is specified in seconds' do
      let(:job) { create(:ci_build, options: { job_timeout: 3, script: ["ls -la\necho aaa", 'date'] }) }
      let(:script) { ["ls -la\necho aaa", 'date'] }

      it_behaves_like 'has correct script'

      it 'has job level timeout' do
        expect(subject.timeout).to eq(3)
      end
    end
  end

  describe '#from_release' do
    subject { described_class.from_release(job) }

    before do
      job.run!
    end

    context 'with release' do
      let(:job) { create(:ci_build, :release_options) }

      it 'returns glab command line' do
        expect(subject.script).to match_array([a_string_including("glab -R $CI_PROJECT_PATH release create")])
      end

      context 'when the FF ci_glab_for_release is disabled' do
        before do
          stub_feature_flags(ci_glab_for_release: false)
        end

        it 'returns release-cli command line' do
          expect(subject.script).to match_array([a_string_including("release-cli create --name")])
        end
      end
    end

    context 'when release is empty' do
      let(:job) { create(:ci_build) }

      it 'does not fabricate an object' do
        is_expected.to be_nil
      end
    end

    context 'with CI catalog release' do
      let_it_be(:project) { create(:project, :catalog_resource_with_components) }
      let_it_be(:ci_catalog_resource) { create(:ci_catalog_resource, project: project) }

      let(:pipeline) { create(:ci_pipeline, project: project) }
      let(:job) { create(:ci_build, :release_options, pipeline: pipeline) }

      it 'returns glab scripts with catalog publish' do
        expect(subject.script).to match_array([a_string_including("glab -R $CI_PROJECT_PATH release create")])
        expect(subject.script).to match_array([a_string_including("--publish-to-catalog")])
      end

      context 'when the FF ci_glab_for_release is disabled' do
        before do
          stub_feature_flags(ci_glab_for_release: false)
        end

        it 'returns release-cli script with catalog publish' do
          expect(subject.script).to match_array([a_string_including("release-cli create")])
          expect(subject.script).to match_array([a_string_including("--catalog-publish")])
        end
      end

      context 'when the FF ci_release_cli_catalog_publish_option is disabled' do
        before do
          stub_feature_flags(ci_release_cli_catalog_publish_option: false, ci_glab_for_release: false)
        end

        it 'returns the release-cli script with catalog publish' do
          expect(subject.script).to match_array([a_string_including("release-cli create")])
          expect(subject.script).not_to match_array([a_string_including("--catalog-publish")])
        end
      end
    end
  end

  describe '#from_after_script' do
    let(:job) { create(:ci_build) }

    subject { described_class.from_after_script(job) }

    before do
      job.run!
    end

    context 'when after_script is empty' do
      it 'does not fabricate an object' do
        is_expected.to be_nil
      end
    end

    context 'when after_script is not empty' do
      let(:job) { create(:ci_build, options: { job_timeout: 60, script: ['bash'], after_script: ['ls -la', 'date'] }) }

      it 'fabricates an object' do
        expect(subject.name).to eq(:after_script)
        expect(subject.script).to eq(['ls -la', 'date'])
        expect(subject.timeout).to eq(60)
        expect(subject.when).to eq('always')
        expect(subject.allow_failure).to be_truthy
      end
    end
  end
end
