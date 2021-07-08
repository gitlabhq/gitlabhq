# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildRunnerPresenter do
  let(:presenter) { described_class.new(build) }
  let(:archive) { { paths: ['sample.txt'] } }

  let(:archive_expectation) do
    {
      artifact_type: :archive,
      artifact_format: :zip,
      paths: archive[:paths],
      untracked: archive[:untracked]
    }
  end

  describe '#artifacts' do
    context "when option contains archive-type artifacts" do
      let(:build) { create(:ci_build, options: { artifacts: archive }) }

      it 'presents correct hash' do
        expect(presenter.artifacts.first).to include(archive_expectation)
      end

      context "when untracked is specified" do
        let(:archive) { { untracked: true } }

        it 'presents correct hash' do
          expect(presenter.artifacts.first).to include(archive_expectation)
        end
      end

      context "when untracked and paths are missing" do
        let(:archive) { { when: 'always' } }

        it 'does not present hash' do
          expect(presenter.artifacts).to be_empty
        end
      end

      context 'when artifacts exclude is defined' do
        let(:build) do
          create(:ci_build, options: { artifacts: { paths: %w[abc], exclude: %w[cde] } })
        end

        it 'includes the list of excluded paths' do
          expect(presenter.artifacts.first).to include(
            artifact_type: :archive,
            artifact_format: :zip,
            paths: %w[abc],
            exclude: %w[cde]
          )
        end
      end

      context 'when artifacts exclude is not defined' do
        let(:build) do
          create(:ci_build, options: { artifacts: { paths: %w[abc] } })
        end

        it 'does not include an empty list of excluded paths' do
          expect(presenter.artifacts.first).not_to have_key(:exclude)
        end
      end
    end

    context "with reports" do
      Ci::JobArtifact::DEFAULT_FILE_NAMES.each do |file_type, filename|
        context file_type.to_s do
          let(:report) { { "#{file_type}": [filename] } }
          let(:build) { create(:ci_build, options: { artifacts: { reports: report } }) }

          let(:report_expectation) do
            {
              name: filename,
              artifact_type: :"#{file_type}",
              artifact_format: Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.fetch(file_type),
              paths: [filename],
              when: 'always'
            }
          end

          it 'presents correct hash' do
            expect(presenter.artifacts.first).to include(report_expectation)
          end
        end
      end
    end

    context "when option has both archive and reports specification" do
      let(:report) { { junit: ['junit.xml'] } }
      let(:build) { create(:ci_build, options: { script: 'echo', artifacts: { **archive, reports: report } }) }

      let(:report_expectation) do
        {
          name: 'junit.xml',
          artifact_type: :junit,
          artifact_format: :gzip,
          paths: ['junit.xml'],
          when: 'always'
        }
      end

      it 'presents correct hash' do
        expect(presenter.artifacts.first).to include(archive_expectation)
        expect(presenter.artifacts.second).to include(report_expectation)
      end

      context "when archive specifies 'expire_in' keyword" do
        let(:archive) { { paths: ['sample.txt'], expire_in: '3 mins 4 sec' } }

        it 'inherits expire_in from archive' do
          expect(presenter.artifacts.first).to include({ **archive_expectation, expire_in: '3 mins 4 sec' })
          expect(presenter.artifacts.second).to include({ **report_expectation, expire_in: '3 mins 4 sec' })
        end
      end
    end

    context "when option has no artifact keywords" do
      let(:build) { create(:ci_build, :no_options) }

      it 'does not present hash' do
        expect(presenter.artifacts).to be_nil
      end
    end
  end

  describe '#ref_type' do
    subject { presenter.ref_type }

    let(:build) { create(:ci_build, tag: tag) }
    let(:tag) { true }

    it 'returns the correct ref type' do
      is_expected.to eq('tag')
    end

    context 'when tag is false' do
      let(:tag) { false }

      it 'returns the correct ref type' do
        is_expected.to eq('branch')
      end
    end
  end

  describe '#git_depth' do
    let(:build) { create(:ci_build) }

    subject(:git_depth) { presenter.git_depth }

    context 'when GIT_DEPTH variable is specified' do
      before do
        create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 1, pipeline: build.pipeline)
      end

      it 'returns its value' do
        expect(git_depth).to eq(1)
      end
    end

    it 'defaults to git depth setting for the project' do
      expect(git_depth).to eq(build.project.ci_default_git_depth)
    end
  end

  describe '#refspecs' do
    subject { presenter.refspecs }

    let(:build) { create(:ci_build) }
    let(:pipeline) { build.pipeline }

    it 'returns the correct refspecs' do
      is_expected.to contain_exactly("+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}",
                                     "+#{pipeline.sha}:refs/pipelines/#{pipeline.id}")
    end

    it 'uses a SHA in the persistent refspec' do
      expect(subject[0]).to match(%r{^\+[0-9a-f]{40}:refs/pipelines/[0-9]+$})
    end

    context 'when ref is tag' do
      let(:build) { create(:ci_build, :tag) }

      it 'returns the correct refspecs' do
        is_expected.to contain_exactly("+refs/tags/#{build.ref}:refs/tags/#{build.ref}",
                                       "+#{pipeline.sha}:refs/pipelines/#{pipeline.id}")
      end

      context 'when GIT_DEPTH is zero' do
        before do
          create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 0, pipeline: build.pipeline)
        end

        it 'returns the correct refspecs' do
          is_expected.to contain_exactly('+refs/tags/*:refs/tags/*',
                                         '+refs/heads/*:refs/remotes/origin/*',
                                         "+#{pipeline.sha}:refs/pipelines/#{pipeline.id}")
        end
      end
    end

    context 'when pipeline is detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.first }
      let(:build) { create(:ci_build, ref: pipeline.ref, pipeline: pipeline) }

      before do
        pipeline.persistent_ref.create # rubocop:disable Rails/SaveBang
      end

      it 'returns the correct refspecs' do
        is_expected
          .to contain_exactly("+#{pipeline.sha}:refs/pipelines/#{pipeline.id}")
      end

      context 'when GIT_DEPTH is zero' do
        before do
          create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 0, pipeline: build.pipeline)
        end

        it 'returns the correct refspecs' do
          is_expected
            .to contain_exactly("+#{pipeline.sha}:refs/pipelines/#{pipeline.id}",
                                '+refs/heads/*:refs/remotes/origin/*',
                                '+refs/tags/*:refs/tags/*')
        end
      end

      context 'when pipeline is legacy detached merge request pipeline' do
        let(:merge_request) { create(:merge_request, :with_legacy_detached_merge_request_pipeline) }

        it 'returns the correct refspecs' do
          is_expected.to contain_exactly("+#{pipeline.sha}:refs/pipelines/#{pipeline.id}",
                                         "+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}")
        end
      end
    end

    context 'when persistent pipeline ref exists' do
      let(:project) { create(:project, :repository) }
      let(:sha) { project.repository.commit.sha }
      let(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }
      let(:build) { create(:ci_build, pipeline: pipeline) }

      before do
        pipeline.persistent_ref.create # rubocop:disable Rails/SaveBang
      end

      it 'exposes the persistent pipeline ref' do
        is_expected
          .to contain_exactly("+#{pipeline.sha}:refs/pipelines/#{pipeline.id}",
                              "+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}")
      end
    end
  end

  describe '#runner_variables' do
    subject { presenter.runner_variables }

    let_it_be(:project_with_flag_disabled) { create(:project, :repository) }
    let_it_be(:project_with_flag_enabled) { create(:project, :repository) }

    before do
      stub_feature_flags(variable_inside_variable: [project_with_flag_enabled])
    end

    shared_examples 'returns an array with the expected variables' do
      it 'returns an array' do
        is_expected.to be_an_instance_of(Array)
      end

      it 'returns the expected variables' do
        is_expected.to eq(presenter.variables.to_runner_variables)
      end
    end

    context 'when FF :variable_inside_variable is disabled' do
      let(:sha) { project_with_flag_disabled.repository.commit.sha }
      let(:pipeline) { create(:ci_pipeline, sha: sha, project: project_with_flag_disabled) }
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it_behaves_like 'returns an array with the expected variables'
    end

    context 'when FF :variable_inside_variable is enabled' do
      let(:sha) { project_with_flag_enabled.repository.commit.sha }
      let(:pipeline) { create(:ci_pipeline, sha: sha, project: project_with_flag_enabled) }
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it_behaves_like 'returns an array with the expected variables'
    end
  end

  describe '#runner_variables subset' do
    subject { presenter.runner_variables.select { |v| %w[A B C].include?(v.fetch(:key)) } }

    let(:build) { create(:ci_build) }

    context 'with references in pipeline variables' do
      before do
        create(:ci_pipeline_variable, key: 'A', value: 'refA-$B', pipeline: build.pipeline)
        create(:ci_pipeline_variable, key: 'B', value: 'refB-$C-$D', pipeline: build.pipeline)
        create(:ci_pipeline_variable, key: 'C', value: 'value', pipeline: build.pipeline)
      end

      context 'when FF :variable_inside_variable is disabled' do
        before do
          stub_feature_flags(variable_inside_variable: false)
        end

        it 'returns non-expanded variables' do
          is_expected.to eq [
                              { key: 'A', value: 'refA-$B', public: false, masked: false },
                              { key: 'B', value: 'refB-$C-$D', public: false, masked: false },
                              { key: 'C', value: 'value', public: false, masked: false }
                            ]
        end
      end

      context 'when FF :variable_inside_variable is enabled' do
        before do
          stub_feature_flags(variable_inside_variable: [build.project])
        end

        it 'returns expanded and sorted variables' do
          is_expected.to eq [
                              { key: 'C', value: 'value', public: false, masked: false },
                              { key: 'B', value: 'refB-value-$D', public: false, masked: false },
                              { key: 'A', value: 'refA-refB-value-$D', public: false, masked: false }
                            ]
        end
      end
    end
  end
end
