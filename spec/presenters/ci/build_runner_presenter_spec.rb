# frozen_string_literal: true

require 'spec_helper'

describe Ci::BuildRunnerPresenter do
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
      let(:build) { create(:ci_build, options: { artifacts: archive } ) }

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
    end

    context "with reports" do
      Ci::JobArtifact::DEFAULT_FILE_NAMES.each do |file_type, filename|
        context file_type.to_s do
          let(:report) { { "#{file_type}": [filename] } }
          let(:build) { create(:ci_build, options: { artifacts: { reports: report } } ) }

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
      let(:build) { create(:ci_build, options: { script: 'echo', artifacts: { **archive, reports: report } } ) }

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

    context 'when feature flag :ci_project_git_depth is disabled' do
      before do
        stub_feature_flags(ci_project_git_depth: { enabled: false })
      end

      it 'defaults to 0' do
        expect(git_depth).to eq(0)
      end
    end
  end

  describe '#refspecs' do
    subject { presenter.refspecs }

    let(:build) { create(:ci_build) }

    it 'returns the correct refspecs' do
      is_expected.to contain_exactly("+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}")
    end

    context 'when ref is tag' do
      let(:build) { create(:ci_build, :tag) }

      it 'returns the correct refspecs' do
        is_expected.to contain_exactly("+refs/tags/#{build.ref}:refs/tags/#{build.ref}")
      end

      context 'when GIT_DEPTH is zero' do
        before do
          create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 0, pipeline: build.pipeline)
        end

        it 'returns the correct refspecs' do
          is_expected.to contain_exactly('+refs/tags/*:refs/tags/*',
                                         '+refs/heads/*:refs/remotes/origin/*')
        end
      end
    end

    context 'when pipeline is detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.first }
      let(:build) { create(:ci_build, ref: pipeline.ref, pipeline: pipeline) }

      context 'when depend_on_persistent_pipeline_ref feature flag is enabled' do
        before do
          stub_feature_flags(ci_force_exposing_merge_request_refs: false)
          pipeline.persistent_ref.create
        end

        it 'returns the correct refspecs' do
          is_expected
            .to contain_exactly("+refs/pipelines/#{pipeline.id}:refs/pipelines/#{pipeline.id}")
        end

        context 'when ci_force_exposing_merge_request_refs feature flag is enabled' do
          before do
            stub_feature_flags(ci_force_exposing_merge_request_refs: true)
          end

          it 'returns the correct refspecs' do
            is_expected
              .to contain_exactly("+refs/pipelines/#{pipeline.id}:refs/pipelines/#{pipeline.id}",
                                  '+refs/merge-requests/1/head:refs/merge-requests/1/head')
          end
        end

        context 'when GIT_DEPTH is zero' do
          before do
            create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 0, pipeline: build.pipeline)
          end

          it 'returns the correct refspecs' do
            is_expected
              .to contain_exactly("+refs/pipelines/#{pipeline.id}:refs/pipelines/#{pipeline.id}",
                                  '+refs/heads/*:refs/remotes/origin/*',
                                  '+refs/tags/*:refs/tags/*')
          end
        end

        context 'when pipeline is legacy detached merge request pipeline' do
          let(:merge_request) { create(:merge_request, :with_legacy_detached_merge_request_pipeline) }

          it 'returns the correct refspecs' do
            is_expected.to contain_exactly("+refs/pipelines/#{pipeline.id}:refs/pipelines/#{pipeline.id}",
                                           "+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}")
          end
        end
      end

      context 'when depend_on_persistent_pipeline_ref feature flag is disabled' do
        before do
          stub_feature_flags(depend_on_persistent_pipeline_ref: false)
        end

        it 'returns the correct refspecs' do
          is_expected
            .to contain_exactly('+refs/merge-requests/1/head:refs/merge-requests/1/head')
        end

        context 'when GIT_DEPTH is zero' do
          before do
            create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 0, pipeline: build.pipeline)
          end

          it 'returns the correct refspecs' do
            is_expected
              .to contain_exactly('+refs/merge-requests/1/head:refs/merge-requests/1/head',
                                  '+refs/heads/*:refs/remotes/origin/*',
                                  '+refs/tags/*:refs/tags/*')
          end
        end

        context 'when pipeline is legacy detached merge request pipeline' do
          let(:merge_request) { create(:merge_request, :with_legacy_detached_merge_request_pipeline) }

          it 'returns the correct refspecs' do
            is_expected.to contain_exactly("+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}")
          end
        end
      end
    end

    context 'when persistent pipeline ref exists' do
      let(:project) { create(:project, :repository) }
      let(:sha) { project.repository.commit.sha }
      let(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }
      let(:build) { create(:ci_build, pipeline: pipeline) }

      before do
        pipeline.persistent_ref.create
      end

      it 'exposes the persistent pipeline ref' do
        is_expected
          .to contain_exactly("+refs/pipelines/#{pipeline.id}:refs/pipelines/#{pipeline.id}",
                              "+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}")
      end
    end
  end
end
