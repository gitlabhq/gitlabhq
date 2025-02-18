# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::UpdatePagesService, feature_category: :pages do
  let_it_be(:project, refind: true) { create(:project, :repository) }

  let_it_be(:old_pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha) }

  let(:options) { {} }
  let(:build) { create(:ci_build, pipeline: pipeline, ref: 'HEAD', options: options) }
  let(:invalid_file) { fixture_file_upload('spec/fixtures/dk.png') }

  let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
  let(:custom_root_file) { fixture_file_upload("spec/fixtures/pages_with_custom_root.zip") }
  let(:empty_file) { fixture_file_upload("spec/fixtures/pages_empty.zip") }
  let(:empty_metadata_filename) { "spec/fixtures/pages_empty.zip.meta" }
  let(:metadata_filename) { "spec/fixtures/pages.zip.meta" }
  let(:custom_root_file_metadata) { "spec/fixtures/pages_with_custom_root.zip.meta" }
  let(:metadata) { fixture_file_upload(metadata_filename) if File.exist?(metadata_filename) }

  subject(:service) { described_class.new(project, build) }

  RSpec.shared_examples 'old deployments' do
    it 'deactivates old deployments from the same project with the same path prefix', :freeze_time do
      other_project = create(:pages_deployment)
      same_project_other_path_prefix = create(:pages_deployment, project: project, path_prefix: 'other')
      same_project = create(:pages_deployment, project: project)

      expect { expect(service.execute[:status]).to eq(:success) }
        .to not_change { other_project.reload.deleted_at }
        .and not_change { same_project_other_path_prefix.reload.deleted_at }
        .and change { same_project.reload.deleted_at }
        .from(nil).to(described_class::OLD_DEPLOYMENTS_DESTRUCTION_DELAY.from_now)
    end
  end

  RSpec.shared_examples 'pages size limit is' do |size_limit|
    context "when size is below the limit" do
      before do
        allow(metadata).to receive(:total_size).and_return(size_limit - 1.megabyte)
        allow(metadata).to receive(:entries).and_return([])
      end

      it 'updates pages correctly' do
        subject.execute

        deploy_status = GenericCommitStatus.last
        expect(deploy_status.description).not_to be_present
        expect(project.pages_deployed?).to eq(true)
      end

      it_behaves_like 'old deployments'
    end

    context "when size is above the limit" do
      before do
        allow(metadata).to receive(:total_size).and_return(size_limit + 1.megabyte)
        allow(metadata).to receive(:entries).and_return([])
      end

      it 'limits the maximum size of gitlab pages' do
        subject.execute

        deploy_status = GenericCommitStatus.last
        expect(deploy_status.description).to match(/artifacts for pages are too large/)
        expect(deploy_status).to be_script_failure
      end
    end
  end

  context 'when a deploy stage already exists', :aggregate_failures do
    let!(:stage) { create(:ci_stage, name: 'deploy', pipeline: pipeline) }

    it 'assigns the deploy stage' do
      expect { service.execute }
        .to change(GenericCommitStatus, :count).by(1)
        .and change(Ci::Stage.where(name: 'deploy'), :count).by(0)

      status = GenericCommitStatus.last

      expect(status.ci_stage).to eq(stage)
      expect(status.ci_stage.name).to eq('deploy')
      expect(status.stage_name).to eq('deploy')
      expect(status.stage).to eq('deploy')
    end
  end

  context 'when a deploy stage does not exists' do
    it 'assigns the deploy stage' do
      expect { service.execute }
        .to change(GenericCommitStatus, :count).by(1)
        .and change(Ci::Stage.where(name: 'deploy'), :count).by(1)

      status = GenericCommitStatus.last

      expect(status.ci_stage.name).to eq('deploy')
      expect(status.stage_name).to eq('deploy')
      expect(status.stage).to eq('deploy')
    end
  end

  context 'for new artifacts' do
    context "for a valid job" do
      let!(:artifacts_archive) { create(:ci_job_artifact, :correct_checksum, file: file, job: build) }

      before do
        create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)

        build.reload
      end

      it_behaves_like 'old deployments'

      it "doesn't delete artifacts after deploying" do
        expect(service.execute[:status]).to eq(:success)

        expect(project.pages_deployed?).to eq(true)
        expect(build.artifacts?).to eq(true)
      end

      it 'succeeds' do
        expect { expect(service.execute[:status]).to eq(:success) }
          .to change { project.pages_deployed? }
          .from(false).to(true)
      end

      it 'publishes a PageDeployedEvent event with project id and namespace id' do
        expected_data = {
          project_id: project.id,
          namespace_id: project.namespace_id,
          root_namespace_id: project.root_namespace.id
        }

        expect { service.execute }.to publish_event(Pages::PageDeployedEvent).with(expected_data)
      end

      it 'creates pages_deployment' do
        expect { expect(service.execute[:status]).to eq(:success) }
          .to change { project.pages_deployments.count }
          .by(1)

        deployment = project.pages_deployments.last

        expect(deployment.size).to eq(file.size)
        expect(deployment.file).to be_present
        expect(deployment.file_count).to eq(3)
        expect(deployment.file_sha256).to eq(artifacts_archive.file_sha256)
        expect(deployment.ci_build_id).to eq(build.id)
        expect(deployment.root_directory).to be_nil
      end

      it 'does not fail if pages_metadata is absent' do
        project.pages_metadatum.destroy!
        project.reload

        expect { expect(service.execute[:status]).to eq(:success) }
          .to change { project.pages_deployments.count }
          .by(1)
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { 'create_pages_deployment' }
        let(:category) { 'Projects::UpdatePagesService' }
        let(:namespace) { project.namespace }

        subject(:track_event) { service.execute }
      end

      context 'when archive does not have pages directory' do
        let(:file) { empty_file }
        let(:metadata_filename) { empty_metadata_filename }

        it 'returns an error' do
          expect(service.execute[:status]).not_to eq(:success)

          expect(GenericCommitStatus.last.description)
            .to eq(
              "Error: You need to either include a `public/` folder in your artifacts, " \
              "or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`")
        end
      end

      context 'when there is a custom root config' do
        let(:file) { custom_root_file }
        let(:metadata_filename) { custom_root_file_metadata }

        before do
          allow(build).to receive(:pages_generator?).and_return(true)
        end

        context 'when the directory specified with `publish` is included in the artifacts' do
          let(:options) { { publish: 'foo' } }

          it 'creates pages_deployment and saves it in the metadata' do
            expect(service.execute[:status]).to eq(:success)

            deployment = project.pages_deployments.last
            expect(deployment.root_directory).to eq(options[:publish])
          end
        end

        context 'when the directory specified with `pages.publish` is included in the artifacts' do
          let(:options) { { pages: { publish: 'foo' } } }

          it 'sets the correct root directory for pages deployment' do
            expect(service.execute[:status]).to eq(:success)

            deployment = project.pages_deployments.last
            expect(deployment.root_directory).to eq('foo')
          end
        end

        context 'when `publish` and `pages.publish` is not specified and there is a folder named `public`' do
          let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
          let(:metadata_filename) { "spec/fixtures/pages.zip.meta" }

          it 'creates pages_deployment and saves it in the metadata' do
            expect(service.execute[:status]).to eq(:success)
          end
        end

        context 'when `publish` and `pages.publish` both are specified' do
          let(:options) { { pages: { publish: 'foo' }, publish: 'bar' } }

          it 'returns an error' do
            expect(service.execute[:status]).not_to eq(:success)

            expect(GenericCommitStatus.last.description)
              .to eq(
                "Either the `publish` or `pages.publish` option may be present in `.gitlab-ci.yml`, but not both.")
          end
        end

        context 'when the directory specified with `publish` is not included in the artifacts' do
          let(:options) { { publish: 'bar' } }

          it 'returns an error' do
            expect(service.execute[:status]).not_to eq(:success)

            expect(GenericCommitStatus.last.description)
              .to eq(
                "Error: You need to either include a `public/` folder in your artifacts, " \
                "or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`")
          end
        end

        context 'when there is a folder named `public`, but `publish` specifies a different one' do
          let(:options) { { publish: 'foo' } }
          let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
          let(:metadata_filename) { "spec/fixtures/pages.zip.meta" }

          it 'returns an error' do
            expect(service.execute[:status]).not_to eq(:success)

            expect(GenericCommitStatus.last.description)
              .to eq(
                "Error: You need to either include a `public/` folder in your artifacts, " \
                "or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`")
          end
        end
      end

      it 'limits pages size' do
        stub_application_setting(max_pages_size: 1)
        expect(service.execute[:status]).not_to eq(:success)
      end

      it 'limits pages file count' do
        create(:plan_limits, :default_plan, pages_file_entries: 2)

        expect(service.execute[:status]).not_to eq(:success)

        expect(GenericCommitStatus.last.description)
          .to eq("pages site contains 3 file entries, while limit is set to 2")
      end

      context 'when timeout happens by DNS error' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:create_pages_deployment).and_raise(SocketError)
          end
        end

        it 'raises an error' do
          expect { service.execute }.to raise_error(SocketError)

          build.reload

          deploy_status = GenericCommitStatus.last
          expect(deploy_status).to be_failed
          expect(project.pages_deployed?).to eq(false)
        end
      end

      context 'when missing artifacts metadata' do
        before do
          allow(build).to receive(:artifacts_metadata?).and_return(false)
        end

        it 'does not raise an error as failed job' do
          service.execute

          build.reload

          deploy_status = GenericCommitStatus.last
          expect(deploy_status).to be_failed
          expect(project.pages_deployed?).to eq(false)
        end
      end

      context 'with background jobs running', :sidekiq_inline do
        it 'succeeds' do
          expect(project.pages_deployed?).to be_falsey
          expect(service.execute[:status]).to eq(:success)
        end
      end

      context "when sha on branch was updated before deployment was uploaded" do
        before do
          expect(service).to receive(:create_pages_deployment).and_wrap_original do |m, *args|
            build.update!(ref: 'feature')
            m.call(*args)
          end
        end

        it 'creates a new pages deployment' do
          expect { expect(service.execute[:status]).to eq(:success) }
            .to change { project.pages_deployments.count }.by(1)

          deployment = project.pages_deployments.last
          expect(deployment.ci_build_id).to eq(build.id)
        end

        it_behaves_like 'old deployments'

        context 'when newer deployment present' do
          it 'fails with outdated reference message' do
            new_pipeline = create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha)
            new_build = create(:ci_build, name: 'pages', pipeline: new_pipeline, ref: 'HEAD')
            create(:pages_deployment, project: project, ci_build: new_build)

            expect(service.execute[:status]).to eq(:error)

            deploy_status = GenericCommitStatus.last
            expect(deploy_status).to be_failed
            expect(deploy_status.description).to eq('build SHA is outdated for this ref')
          end
        end
      end

      it 'fails when uploaded deployment size is wrong' do
        allow_next_instance_of(PagesDeployment) do |deployment|
          allow(deployment)
            .to receive(:file)
            .and_return(instance_double(Pages::DeploymentUploader, size: file.size + 1))
        end

        expect(service.execute[:status]).not_to eq(:success)

        expect(GenericCommitStatus.last.description)
          .to eq('The uploaded artifact size does not match the expected value')
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
      expect { service.execute }
        .to raise_error("Validation failed: File sha256 can't be blank")
    end
  end

  it 'fails if no artifacts' do
    expect(service.execute[:status]).not_to eq(:success)
  end

  it 'fails for invalid archive' do
    create(:ci_job_artifact, :archive, file: invalid_file, job: build)
    expect(service.execute[:status]).not_to eq(:success)
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

  context 'when retrying the job' do
    let(:stage) { create(:ci_stage, position: 1_000_000, name: 'deploy', pipeline: pipeline) }
    let!(:older_deploy_job) do
      create(
        :generic_commit_status,
        :failed,
        pipeline: pipeline,
        ref: build.ref,
        ci_stage: stage,
        name: 'pages:deploy'
      )
    end

    before do
      create(:ci_job_artifact, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)
      build.reload
    end

    it 'marks older pages:deploy jobs retried' do
      expect(service.execute[:status]).to eq(:success)

      expect(older_deploy_job.reload).to be_retried

      deploy_status = GenericCommitStatus.last
      expect(deploy_status.ci_stage).to eq(stage)
      expect(deploy_status.stage_idx).to eq(stage.position)
    end
  end
end
