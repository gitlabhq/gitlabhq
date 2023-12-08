# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::DeploymentUpdate, feature_category: :pages do
  let_it_be(:project, refind: true) { create(:project, :repository) }

  let_it_be(:old_pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD~~').sha) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD~').sha) }

  let(:build) { create(:ci_build, pipeline: pipeline, ref: 'HEAD') }
  let(:invalid_file) { fixture_file_upload('spec/fixtures/dk.png') }

  let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
  let(:empty_file) { fixture_file_upload("spec/fixtures/pages_empty.zip") }
  let(:empty_metadata_filename) { "spec/fixtures/pages_empty.zip.meta" }
  let(:metadata_filename) { "spec/fixtures/pages.zip.meta" }
  let(:metadata) { fixture_file_upload(metadata_filename) if File.exist?(metadata_filename) }

  subject(:pages_deployment_update) { described_class.new(project, build) }

  context 'for new artifacts' do
    context 'for a valid job' do
      let!(:artifacts_archive) { create(:ci_job_artifact, :correct_checksum, file: file, job: build) }

      before do
        create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)

        build.reload
      end

      it 'is valid' do
        expect(pages_deployment_update).to be_valid
      end

      context 'when missing artifacts metadata' do
        before do
          expect(build).to receive(:artifacts_metadata?).and_return(false)
        end

        it 'is invalid' do
          expect(pages_deployment_update).not_to be_valid
          expect(pages_deployment_update.errors.full_messages).to include('missing artifacts metadata')
        end
      end
    end

    it 'is invalid for invalid archive' do
      create(:ci_job_artifact, :archive, file: invalid_file, job: build)

      expect(pages_deployment_update).not_to be_valid
      expect(pages_deployment_update.errors.full_messages).to include('missing artifacts metadata')
    end
  end

  describe 'maximum pages artifacts size' do
    let(:metadata) { spy('metadata') } # rubocop: disable RSpec/VerifiedDoubles

    before do
      file = fixture_file_upload('spec/fixtures/pages.zip')
      metafile = fixture_file_upload('spec/fixtures/pages.zip.meta')

      create(:ci_job_artifact, :archive, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, :metadata, file: metafile, job: build)

      allow(build).to receive(:artifacts_metadata_entry)
        .and_return(metadata)
    end

    context 'when maximum pages size is set to zero' do
      before do
        stub_application_setting(max_pages_size: 0)
      end

      context "when size is above the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(1.megabyte)
          allow(metadata).to receive(:entries).and_return([])
        end

        it 'is valid' do
          expect(pages_deployment_update).to be_valid
        end
      end
    end

    context 'when size is limited on the instance level' do
      before do
        stub_application_setting(max_pages_size: 100)
      end

      context "when size is below the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(1.megabyte)
          allow(metadata).to receive(:entries).and_return([])
        end

        it 'is valid' do
          expect(pages_deployment_update).to be_valid
        end
      end

      context "when size is above the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(101.megabyte)
          allow(metadata).to receive(:entries).and_return([])
        end

        it 'is invalid' do
          expect(pages_deployment_update).not_to be_valid
          expect(pages_deployment_update.errors.full_messages)
            .to include('artifacts for pages are too large: 105906176')
        end
      end
    end
  end

  context 'when retrying the job' do
    let!(:older_deploy_job) do
      create(
        :generic_commit_status,
        :failed,
        pipeline: pipeline,
        ref: build.ref,
        stage: 'deploy',
        name: 'pages:deploy'
      )
    end

    before do
      create(:ci_job_artifact, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)
      build.reload
    end

    it 'marks older pages:deploy jobs retried' do
      expect(pages_deployment_update).to be_valid
    end
  end

  context 'when validating if current build is outdated' do
    before do
      create(:ci_job_artifact, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)
      build.reload
    end

    context 'when there is NOT a newer build' do
      it 'does not fail' do
        expect(pages_deployment_update).to be_valid
      end
    end

    context 'when there is a newer build' do
      before do
        new_pipeline = create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha)
        new_build = create(:ci_build, name: 'pages', pipeline: new_pipeline, ref: 'HEAD')
        create(:ci_job_artifact, :correct_checksum, file: file, job: new_build)
        create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: new_build)
        create(:pages_deployment, project: project, ci_build: new_build)
        new_build.reload
      end

      it 'fails with outdated reference message' do
        expect(pages_deployment_update).not_to be_valid
        expect(pages_deployment_update.errors.full_messages)
          .to include('build SHA is outdated for this ref')
      end
    end
  end
end
