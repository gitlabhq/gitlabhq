# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Pages::DeploymentValidations, :aggregate_failures, feature_category: :pages do
  let_it_be(:project, refind: true) { create(:project, :repository) }

  let_it_be(:old_pipeline) { create(:ci_pipeline, project: project, sha: project.commit("HEAD~~").sha) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit("HEAD~").sha) }

  let(:build_options) { {} }
  let(:build) { create(:ci_build, :pages, pipeline: pipeline, options: build_options) }

  before do
    stub_pages_setting(enabled: true)
  end

  subject(:validations) { described_class.new(project, build) }

  shared_examples "valid pages deployment" do
    specify do
      expect(validations.valid?).to eq(true)
      expect(validations.errors.full_messages).to eq([])
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
      include_examples "valid pages deployment"

      context "when build does not have artifacts" do
        before do
          build.job_artifacts_archive.update!(file: nil)
        end

        include_examples "invalid pages deployment",
          message: "missing pages artifacts"
      end

      context "when build does not have artifacts metadata" do
        before do
          build.job_artifacts_metadata.update!(file: nil)
        end

        include_examples "invalid pages deployment",
          message: "missing artifacts metadata"
      end
    end
  end

  describe 'public folder' do
    context 'when archive does not have pages directory' do
      before do
        build.job_artifacts_archive.update!(file: fixture_file_upload("spec/fixtures/pages_empty.zip"))
        build.job_artifacts_metadata.update!(file: fixture_file_upload("spec/fixtures/pages_empty.zip.meta"))
      end

      include_examples "invalid pages deployment",
        message: <<~MSG.squish
        Error: You need to either include a `public/` folder in your artifacts,
        or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`
        MSG
    end

    context 'when there is a custom root config' do
      before do
        build.job_artifacts_archive.update!(file: fixture_file_upload("spec/fixtures/pages_with_custom_root.zip"))
        build.job_artifacts_metadata.update!(file: fixture_file_upload("spec/fixtures/pages_with_custom_root.zip.meta"))
      end

      context 'and the directory specified with `publish` is included in the artifacts' do
        let(:build_options) { { publish: 'foo' } }

        include_examples "valid pages deployment"
      end

      context 'and the directory specified with `pages.publish` is included in the artifacts' do
        let(:build_options) { { pages: { publish: 'foo' } } }

        include_examples "valid pages deployment"
      end

      context 'and `publish` is present in root as well as pages' do
        let(:build_options) { { publish: 'foo', pages: { publish: 'foo' } } }

        include_examples "invalid pages deployment",
          message: <<~MSG.squish
          Either the `publish` or `pages.publish` option may be present in `.gitlab-ci.yml`, but not both.
          MSG
      end

      context 'and the directory specified with `publish` is not included in the artifacts' do
        let(:build_options) { { publish: 'bar' } }

        include_examples "invalid pages deployment",
          message: <<~MSG.squish
          Error: You need to either include a `public/` folder in your artifacts,
          or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`
          MSG
      end

      context 'and there is a folder named `public`, but `publish` specifies a different one' do
        let(:build_options) { { publish: 'foo' } }

        before do
          build.job_artifacts_archive.update!(file: fixture_file_upload("spec/fixtures/pages.zip"))
          build.job_artifacts_metadata.update!(file: fixture_file_upload("spec/fixtures/pages.zip.meta"))
        end

        include_examples "invalid pages deployment",
          message: <<~MSG.squish
          Error: You need to either include a `public/` folder in your artifacts,
          or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`
          MSG
      end
    end
  end

  describe "maximum pages artifacts size" do
    let(:metadata_entry) do
      instance_double(
        ::Gitlab::Ci::Build::Artifacts::Metadata::Entry,
        entries: [],
        total_size: 50.megabyte
      )
    end

    before do
      allow(build)
        .to receive(:artifacts_metadata_entry)
        .and_return(metadata_entry)
    end

    context "when maximum pages size is set to zero" do
      before do
        stub_application_setting(max_pages_size: 0)
      end

      context "and size is above the limit" do
        before do
          allow(metadata_entry).to receive(:total_size).and_return(1.megabyte)
          allow(metadata_entry).to receive(:entries).and_return([])
        end

        include_examples "valid pages deployment"
      end
    end

    context "when size is limited on the instance level" do
      before do
        stub_application_setting(max_pages_size: 100)
      end

      context "and size is below the limit" do
        before do
          allow(metadata_entry).to receive(:total_size).and_return(1.megabyte)
          allow(metadata_entry).to receive(:entries).and_return([])
        end

        include_examples "valid pages deployment"
      end

      context "and size is above the limit" do
        before do
          allow(metadata_entry).to receive(:total_size).and_return(101.megabyte)
          allow(metadata_entry).to receive(:entries).and_return([])
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

    include_examples "valid pages deployment"
  end

  context "when validating if current build is outdated" do
    context "and there is NOT a newer build" do
      include_examples "valid pages deployment"
    end

    context "and there is a newer build" do
      before do
        new_pipeline = create(:ci_pipeline, project: project, sha: project.commit("HEAD").sha)
        new_build = create(:ci_build, :pages, project: project, pipeline: new_pipeline)
        create(:pages_deployment, project: project, ci_build: new_build)
      end

      include_examples "invalid pages deployment",
        message: "build SHA is outdated for this ref"
    end
  end
end
