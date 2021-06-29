# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::UpdatePagesService do
  let_it_be(:project, refind: true) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha) }

  let(:build) { create(:ci_build, pipeline: pipeline, ref: 'HEAD') }
  let(:invalid_file) { fixture_file_upload('spec/fixtures/dk.png') }

  let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
  let(:empty_file) { fixture_file_upload("spec/fixtures/pages_empty.zip") }
  let(:metadata_filename) { "spec/fixtures/pages.zip.meta" }
  let(:metadata) { fixture_file_upload(metadata_filename) if File.exist?(metadata_filename) }

  subject { described_class.new(project, build) }

  before do
    stub_feature_flags(skip_pages_deploy_to_legacy_storage: false)
    project.legacy_remove_pages
  end

  context '::TMP_EXTRACT_PATH' do
    subject { described_class::TMP_EXTRACT_PATH }

    it { is_expected.not_to match(Gitlab::PathRegex.namespace_format_regex) }
  end

  context 'for new artifacts' do
    context "for a valid job" do
      let!(:artifacts_archive) { create(:ci_job_artifact, :correct_checksum, file: file, job: build) }

      before do
        create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)

        build.reload
      end

      it "doesn't delete artifacts after deploying" do
        expect(execute).to eq(:success)

        expect(project.pages_metadatum).to be_deployed
        expect(build.artifacts?).to eq(true)
      end

      it 'succeeds' do
        expect(project.pages_deployed?).to be_falsey
        expect(execute).to eq(:success)
        expect(project.pages_metadatum).to be_deployed
        expect(project.pages_metadatum.artifacts_archive).to eq(artifacts_archive)
        expect(project.pages_deployed?).to be_truthy

        # Check that all expected files are extracted
        %w[index.html zero .hidden/file].each do |filename|
          expect(File.exist?(File.join(project.pages_path, 'public', filename))).to be_truthy
        end
      end

      it 'creates a temporary directory with the project and build ID' do
        expect(Dir).to receive(:mktmpdir).with("project-#{project.id}-build-#{build.id}-", anything).and_call_original

        subject.execute
      end

      it "doesn't deploy to legacy storage if it's disabled" do
        allow(Settings.pages.local_store).to receive(:enabled).and_return(false)

        expect(execute).to eq(:success)
        expect(project.pages_deployed?).to be_truthy

        expect(File.exist?(File.join(project.pages_path, 'public', 'index.html'))).to eq(false)
      end

      it "doesn't deploy to legacy storage if skip_pages_deploy_to_legacy_storage is enabled" do
        allow(Settings.pages.local_store).to receive(:enabled).and_return(true)
        stub_feature_flags(skip_pages_deploy_to_legacy_storage: true)

        expect(execute).to eq(:success)
        expect(project.pages_deployed?).to be_truthy

        expect(File.exist?(File.join(project.pages_path, 'public', 'index.html'))).to eq(false)
      end

      it 'creates pages_deployment and saves it in the metadata' do
        expect do
          expect(execute).to eq(:success)
        end.to change { project.pages_deployments.count }.by(1)

        deployment = project.pages_deployments.last

        expect(deployment.size).to eq(file.size)
        expect(deployment.file).to be
        expect(deployment.file_count).to eq(3)
        expect(deployment.file_sha256).to eq(artifacts_archive.file_sha256)
        expect(project.pages_metadatum.reload.pages_deployment_id).to eq(deployment.id)
      end

      it 'fails if another deployment is in progress' do
        subject.try_obtain_lease do
          expect do
            execute
          end.to raise_error("Failed to deploy pages - other deployment is in progress")

          expect(GenericCommitStatus.last.description).to eq("Failed to deploy pages - other deployment is in progress")
        end
      end

      it 'fails if sha on branch was updated before deployment was uploaded' do
        expect(subject).to receive(:create_pages_deployment).and_wrap_original do |m, *args|
          build.update!(ref: 'feature')
          m.call(*args)
        end

        expect(execute).not_to eq(:success)
        expect(project.pages_metadatum).not_to be_deployed

        expect(deploy_status).to be_failed
        expect(deploy_status.description).to eq('build SHA is outdated for this ref')
      end

      it 'does not fail if pages_metadata is absent' do
        project.pages_metadatum.destroy!
        project.reload

        expect do
          expect(execute).to eq(:success)
        end.to change { project.pages_deployments.count }.by(1)

        expect(project.pages_metadatum.reload.pages_deployment).to eq(project.pages_deployments.last)
      end

      context 'when there is an old pages deployment' do
        let!(:old_deployment_from_another_project) { create(:pages_deployment) }
        let!(:old_deployment) { create(:pages_deployment, project: project) }

        it 'schedules a destruction of older deployments' do
          expect(DestroyPagesDeploymentsWorker).to(
            receive(:perform_in).with(described_class::OLD_DEPLOYMENTS_DESTRUCTION_DELAY,
                                      project.id,
                                      instance_of(Integer))
          )

          execute
        end

        it 'removes older deployments', :sidekiq_inline do
          expect do
            execute
          end.not_to change { PagesDeployment.count } # it creates one and deletes one

          expect(PagesDeployment.find_by_id(old_deployment.id)).to be_nil
        end
      end

      it 'limits pages size' do
        stub_application_setting(max_pages_size: 1)
        expect(execute).not_to eq(:success)
      end

      it 'removes pages after destroy' do
        expect(PagesWorker).to receive(:perform_in)
        expect(project.pages_deployed?).to be_falsey
        expect(Dir.exist?(File.join(project.pages_path))).to be_falsey

        expect(execute).to eq(:success)

        expect(project.pages_metadatum).to be_deployed
        expect(project.pages_deployed?).to be_truthy
        expect(Dir.exist?(File.join(project.pages_path))).to be_truthy

        project.destroy!

        expect(Dir.exist?(File.join(project.pages_path))).to be_falsey
        expect(ProjectPagesMetadatum.find_by_project_id(project)).to be_nil
      end

      it 'fails if sha on branch is not latest' do
        build.update!(ref: 'feature')

        expect(execute).not_to eq(:success)
        expect(project.pages_metadatum).not_to be_deployed

        expect(deploy_status).to be_failed
        expect(deploy_status.description).to eq('build SHA is outdated for this ref')
      end

      context 'when using empty file' do
        let(:file) { empty_file }

        it 'fails to extract' do
          expect { execute }
            .to raise_error(Projects::UpdatePagesService::FailedToExtractError)
        end
      end

      context 'when using pages with non-writeable public' do
        let(:file) { fixture_file_upload("spec/fixtures/pages_non_writeable.zip") }

        context 'when using RubyZip' do
          it 'succeeds to extract' do
            expect(execute).to eq(:success)
            expect(project.pages_metadatum).to be_deployed
          end
        end
      end

      context 'when timeout happens by DNS error' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:extract_zip_archive!).and_raise(SocketError)
          end
        end

        it 'raises an error' do
          expect { execute }.to raise_error(SocketError)

          build.reload
          expect(deploy_status).to be_failed
          expect(project.pages_metadatum).not_to be_deployed
        end
      end

      context 'when failed to extract zip artifacts' do
        before do
          expect_next_instance_of(described_class) do |instance|
            expect(instance).to receive(:extract_zip_archive!)
              .and_raise(Projects::UpdatePagesService::FailedToExtractError)
          end
        end

        it 'raises an error' do
          expect { execute }
            .to raise_error(Projects::UpdatePagesService::FailedToExtractError)

          build.reload
          expect(deploy_status).to be_failed
          expect(project.pages_metadatum).not_to be_deployed
        end
      end

      context 'when missing artifacts metadata' do
        before do
          expect(build).to receive(:artifacts_metadata?).and_return(false)
        end

        it 'does not raise an error as failed job' do
          execute

          build.reload
          expect(deploy_status).to be_failed
          expect(project.pages_metadatum).not_to be_deployed
        end
      end

      context 'with background jobs running', :sidekiq_inline do
        it 'succeeds' do
          expect(project.pages_deployed?).to be_falsey
          expect(execute).to eq(:success)
        end
      end
    end
  end

  # this situation should never happen in real life because all new archives have sha256
  # and we only use new archives
  # this test is here just to clarify that this behavior is intentional
  context 'when artifacts archive does not have sha256' do
    let!(:artifacts_archive) { create(:ci_job_artifact, file: file, job: build) }

    before do
      create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)

      build.reload
    end

    it 'fails with exception raised' do
      expect do
        execute
      end.to raise_error("Validation failed: File sha256 can't be blank")
    end
  end

  it 'fails to remove project pages when no pages is deployed' do
    expect(PagesWorker).not_to receive(:perform_in)
    expect(project.pages_deployed?).to be_falsey
    project.destroy!
  end

  it 'fails if no artifacts' do
    expect(execute).not_to eq(:success)
  end

  it 'fails for invalid archive' do
    create(:ci_job_artifact, :archive, file: invalid_file, job: build)
    expect(execute).not_to eq(:success)
  end

  describe 'maximum pages artifacts size' do
    let(:metadata) { spy('metadata') }

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

      it_behaves_like 'pages size limit is', ::Gitlab::Pages::MAX_SIZE
    end

    context 'when size is limited on the instance level' do
      before do
        stub_application_setting(max_pages_size: 100)
      end

      it_behaves_like 'pages size limit is', 100.megabytes
    end
  end

  context 'when file size is spoofed' do
    let(:metadata) { spy('metadata') }

    include_context 'pages zip with spoofed size'

    before do
      file = fixture_file_upload(fake_zip_path, 'pages.zip')
      metafile = fixture_file_upload('spec/fixtures/pages.zip.meta')

      create(:ci_job_artifact, :archive, file: file, job: build)
      create(:ci_job_artifact, :metadata, file: metafile, job: build)

      allow(build).to receive(:artifacts_metadata_entry)
                        .and_return(metadata)
      allow(metadata).to receive(:total_size).and_return(100)
    end

    it 'raises an error' do
      expect do
        subject.execute
      end.to raise_error(Projects::UpdatePagesService::FailedToExtractError,
                         'Entry public/index.html should be 1B but is larger when inflated')
      expect(deploy_status).to be_script_failure
    end
  end

  context 'when retrying the job' do
    let!(:older_deploy_job) do
      create(:generic_commit_status, :failed, pipeline: pipeline,
                                              ref: build.ref,
                                              stage: 'deploy',
                                              name: 'pages:deploy')
    end

    before do
      create(:ci_job_artifact, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)
      build.reload
    end

    it 'marks older pages:deploy jobs retried' do
      expect(execute).to eq(:success)

      expect(older_deploy_job.reload).to be_retried
    end

    context 'when FF ci_fix_commit_status_retried is disabled' do
      before do
        stub_feature_flags(ci_fix_commit_status_retried: false)
      end

      it 'does not mark older pages:deploy jobs retried' do
        expect(execute).to eq(:success)

        expect(older_deploy_job.reload).not_to be_retried
      end
    end
  end

  private

  def deploy_status
    GenericCommitStatus.find_by(name: 'pages:deploy')
  end

  def execute
    subject.execute[:status]
  end
end
