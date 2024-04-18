# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Pages::DeploymentValidations, feature_category: :pages do
  let_it_be(:project, refind: true) { create(:project, :repository) }

  let_it_be(:old_pipeline) { create(:ci_pipeline, project: project, sha: project.commit("HEAD~~").sha) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit("HEAD~").sha) }

  let(:build_options) { {} }
  let(:build) { create(:ci_build, name: "pages", ref: "HEAD", pipeline: pipeline, options: build_options) }

  let(:invalid_file) { fixture_file_upload("spec/fixtures/dk.png") }
  let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
  let(:metadata) { fixture_file_upload("spec/fixtures/pages.zip.meta") }

  subject(:validations) { described_class.new(project, build) }

  before do
    stub_pages_setting(enabled: true)
  end

  def add_build_artifacts!
    create(:ci_job_artifact, :correct_checksum, file: file, job: build)
    create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)
    build.reload
  end

  shared_examples "valid pages deployment" do
    specify do
      expect(validations.valid?).to eq(true)
    end
  end

  shared_examples "invalid pages deployment" do |message:|
    specify do
      expect(validations.valid?).to eq(false)
      expect(validations.errors.full_messages).to include(message)
    end
  end

  context "for new artifacts" do
    context "for a valid job" do
      before do
        add_build_artifacts!
      end

      include_examples "valid pages deployment"

      context "when missing artifacts metadata" do
        before do
          allow(build).to receive(:artifacts_metadata?).and_return(false)
        end

        include_examples "invalid pages deployment",
          message: "missing artifacts metadata"
      end
    end

    context "for an invalid artifact archive" do
      before do
        create(:ci_job_artifact, :archive, file: invalid_file, job: build)
      end

      include_examples "invalid pages deployment",
        message: "missing artifacts metadata"
    end
  end

  describe "maximum pages artifacts size" do
    before do
      add_build_artifacts!

      allow(build)
        .to receive(:artifacts_metadata_entry)
        .and_return(metadata)
    end

    context "when maximum pages size is set to zero" do
      before do
        stub_application_setting(max_pages_size: 0)
      end

      context "when size is above the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(1.megabyte)
          allow(metadata).to receive(:entries).and_return([])
        end

        include_examples "valid pages deployment"
      end
    end

    context "when size is limited on the instance level" do
      before do
        stub_application_setting(max_pages_size: 100)
      end

      context "when size is below the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(1.megabyte)
          allow(metadata).to receive(:entries).and_return([])
        end

        include_examples "valid pages deployment"
      end

      context "when size is above the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(101.megabyte)
          allow(metadata).to receive(:entries).and_return([])
        end

        include_examples "invalid pages deployment",
          message: "artifacts for pages are too large: 105906176"
      end
    end
  end

  context "when retrying the job" do
    let!(:older_deploy_job) do
      create(
        :generic_commit_status,
        :failed,
        pipeline: pipeline,
        ref: build.ref,
        stage: "deploy",
        name: "pages:deploy"
      )
    end

    before do
      create(:ci_job_artifact, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)
      build.reload
    end

    include_examples "valid pages deployment"
  end

  context "when validating if current build is outdated" do
    before do
      create(:ci_job_artifact, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)
      build.reload
    end

    context "when there is NOT a newer build" do
      include_examples "valid pages deployment"
    end

    context "when there is a newer build" do
      before do
        new_pipeline = create(:ci_pipeline, project: project, sha: project.commit("HEAD").sha)
        new_build = create(:ci_build, name: "pages", pipeline: new_pipeline, ref: "HEAD")
        create(:ci_job_artifact, :correct_checksum, file: file, job: new_build)
        create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: new_build)
        create(:pages_deployment, project: project, ci_build: new_build)
        new_build.reload
      end

      include_examples "invalid pages deployment",
        message: "build SHA is outdated for this ref"
    end
  end
end
