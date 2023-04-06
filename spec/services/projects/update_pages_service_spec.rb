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

  subject { described_class.new(project, build) }

  context 'when a deploy stage already exists', :aggregate_failures do
    let!(:stage) { create(:ci_stage, name: 'deploy', pipeline: pipeline) }

    it 'assigns the deploy stage' do
      expect { subject.execute }
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
      expect { subject.execute }
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

      it "doesn't delete artifacts after deploying" do
        expect(execute).to eq(:success)

        expect(project.pages_metadatum).to be_deployed
        expect(build.artifacts?).to eq(true)
      end

      it 'succeeds' do
        expect(project.pages_deployed?).to be_falsey
        expect(execute).to eq(:success)
        expect(project.pages_metadatum).to be_deployed
        expect(project.pages_deployed?).to be_truthy
      end

      it 'publishes a PageDeployedEvent event with project id and namespace id' do
        expected_data = {
          project_id: project.id,
          namespace_id: project.namespace_id,
          root_namespace_id: project.root_namespace.id
        }

        expect { subject.execute }.to publish_event(Pages::PageDeployedEvent).with(expected_data)
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
        expect(deployment.ci_build_id).to eq(build.id)
        expect(deployment.root_directory).to be_nil
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
            receive(:perform_in).with(
              described_class::OLD_DEPLOYMENTS_DESTRUCTION_DELAY,
              project.id,
              instance_of(Integer)
            )
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

      context 'when archive does not have pages directory' do
        let(:file) { empty_file }
        let(:metadata_filename) { empty_metadata_filename }

        it 'returns an error' do
          expect(execute).not_to eq(:success)

          expect(GenericCommitStatus.last.description).to eq("Error: You need to either include a `public/` folder in your artifacts, or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`")
        end
      end

      context 'when there is a custom root config' do
        let(:file) { custom_root_file }
        let(:metadata_filename) { custom_root_file_metadata }

        context 'when the directory specified with `publish` is included in the artifacts' do
          let(:options) { { publish: 'foo' } }

          it 'creates pages_deployment and saves it in the metadata' do
            expect(execute).to eq(:success)

            deployment = project.pages_deployments.last
            expect(deployment.root_directory).to eq(options[:publish])
          end
        end

        context 'when the directory specified with `publish` is not included in the artifacts' do
          let(:options) { { publish: 'bar' } }

          it 'returns an error' do
            expect(execute).not_to eq(:success)

            expect(GenericCommitStatus.last.description).to eq("Error: You need to either include a `public/` folder in your artifacts, or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`")
          end
        end

        context 'when there is a folder named `public`, but `publish` specifies a different one' do
          let(:options) { { publish: 'foo' } }
          let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
          let(:metadata_filename) { "spec/fixtures/pages.zip.meta" }

          it 'returns an error' do
            expect(execute).not_to eq(:success)

            expect(GenericCommitStatus.last.description).to eq("Error: You need to either include a `public/` folder in your artifacts, or specify which one to use for Pages using `publish` in `.gitlab-ci.yml`")
          end
        end
      end

      it 'limits pages size' do
        stub_application_setting(max_pages_size: 1)
        expect(execute).not_to eq(:success)
      end

      it 'limits pages file count' do
        create(:plan_limits, :default_plan, pages_file_entries: 2)

        expect(execute).not_to eq(:success)

        expect(GenericCommitStatus.last.description).to eq("pages site contains 3 file entries, while limit is set to 2")
      end

      context 'when timeout happens by DNS error' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:create_pages_deployment).and_raise(SocketError)
          end
        end

        it 'raises an error' do
          expect { execute }.to raise_error(SocketError)

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

      context "when sha on branch was updated before deployment was uploaded" do
        before do
          expect(subject).to receive(:create_pages_deployment).and_wrap_original do |m, *args|
            build.update!(ref: 'feature')
            m.call(*args)
          end
        end

        shared_examples 'successfully deploys' do
          it 'succeeds' do
            expect do
              expect(execute).to eq(:success)
            end.to change { project.pages_deployments.count }.by(1)

            deployment = project.pages_deployments.last
            expect(deployment.ci_build_id).to eq(build.id)
          end
        end

        include_examples 'successfully deploys'

        context 'when old deployment present' do
          before do
            old_build = create(:ci_build, pipeline: old_pipeline, ref: 'HEAD')
            old_deployment = create(:pages_deployment, ci_build: old_build, project: project)
            project.update_pages_deployment!(old_deployment)
          end

          include_examples 'successfully deploys'
        end

        context 'when newer deployment present' do
          before do
            new_pipeline = create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha)
            new_build = create(:ci_build, pipeline: new_pipeline, ref: 'HEAD')
            new_deployment = create(:pages_deployment, ci_build: new_build, project: project)
            project.update_pages_deployment!(new_deployment)
          end

          it 'fails with outdated reference message' do
            expect(execute).to eq(:error)
            expect(project.reload.pages_metadatum).not_to be_deployed

            expect(deploy_status).to be_failed
            expect(deploy_status.description).to eq('build SHA is outdated for this ref')
          end
        end
      end

      it 'fails when uploaded deployment size is wrong' do
        allow_next_instance_of(PagesDeployment) do |deployment|
          allow(deployment)
            .to receive(:size)
            .and_return(file.size + 1)
        end

        expect(execute).not_to eq(:success)

        expect(GenericCommitStatus.last.description).to eq('The uploaded artifact size does not match the expected value')
        project.pages_metadatum.reload
        expect(project.pages_metadatum).not_to be_deployed
        expect(project.pages_metadatum.pages_deployment).to be_nil
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
      expect(execute).to eq(:success)

      expect(older_deploy_job.reload).to be_retried
      expect(deploy_status.ci_stage).to eq(stage)
      expect(deploy_status.stage_idx).to eq(stage.position)
    end
  end

  private

  def deploy_status
    GenericCommitStatus.where(name: 'pages:deploy').last
  end

  def execute
    subject.execute[:status]
  end
end
