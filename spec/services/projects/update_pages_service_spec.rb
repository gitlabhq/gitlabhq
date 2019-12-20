# frozen_string_literal: true

require "spec_helper"

describe Projects::UpdatePagesService do
  set(:project) { create(:project, :repository) }
  set(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha) }
  set(:build) { create(:ci_build, pipeline: pipeline, ref: 'HEAD') }
  let(:invalid_file) { fixture_file_upload('spec/fixtures/dk.png') }

  let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
  let(:empty_file) { fixture_file_upload("spec/fixtures/pages_empty.zip") }
  let(:metadata_filename) { "spec/fixtures/pages.zip.meta" }
  let(:metadata) { fixture_file_upload(metadata_filename) if File.exist?(metadata_filename) }

  subject { described_class.new(project, build) }

  before do
    stub_feature_flags(safezip_use_rubyzip: true)

    project.remove_pages
  end

  context '::TMP_EXTRACT_PATH' do
    subject { described_class::TMP_EXTRACT_PATH }

    it { is_expected.not_to match(Gitlab::PathRegex.namespace_format_regex) }
  end

  context 'for new artifacts' do
    context "for a valid job" do
      before do
        create(:ci_job_artifact, file: file, job: build)
        create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)

        build.reload
      end

      describe 'pages artifacts' do
        it "doesn't delete artifacts after deploying" do
          expect(execute).to eq(:success)

          expect(project.pages_metadatum).to be_deployed
          expect(build.artifacts?).to eq(true)
        end
      end

      it 'succeeds' do
        expect(project.pages_deployed?).to be_falsey
        expect(execute).to eq(:success)
        expect(project.pages_metadatum).to be_deployed
        expect(project.pages_deployed?).to be_truthy

        # Check that all expected files are extracted
        %w[index.html zero .hidden/file].each do |filename|
          expect(File.exist?(File.join(project.public_pages_path, filename))).to be_truthy
        end
      end

      it 'limits pages size' do
        stub_application_setting(max_pages_size: 1)
        expect(execute).not_to eq(:success)
      end

      it 'removes pages after destroy' do
        expect(PagesWorker).to receive(:perform_in)
        expect(project.pages_deployed?).to be_falsey

        expect(execute).to eq(:success)

        expect(project.pages_metadatum).to be_deployed
        expect(project.pages_deployed?).to be_truthy

        project.destroy

        expect(project.pages_deployed?).to be_falsey
        expect(ProjectPagesMetadatum.find_by_project_id(project)).to be_nil
      end

      it 'fails if sha on branch is not latest' do
        build.update(ref: 'feature')

        expect(execute).not_to eq(:success)
        expect(project.pages_metadatum).not_to be_deployed
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
          before do
            stub_feature_flags(safezip_use_rubyzip: true)
          end

          it 'succeeds to extract' do
            expect(execute).to eq(:success)
            expect(project.pages_metadatum).to be_deployed
          end
        end
      end

      context 'when timeout happens by DNS error' do
        before do
          allow_any_instance_of(described_class)
            .to receive(:extract_zip_archive!).and_raise(SocketError)
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
          expect_any_instance_of(described_class)
            .to receive(:extract_zip_archive!)
            .and_raise(Projects::UpdatePagesService::FailedToExtractError)
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
    end
  end

  it 'fails to remove project pages when no pages is deployed' do
    expect(PagesWorker).not_to receive(:perform_in)
    expect(project.pages_deployed?).to be_falsey
    project.destroy
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

      create(:ci_job_artifact, :archive, file: file, job: build)
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

  def deploy_status
    GenericCommitStatus.find_by(name: 'pages:deploy')
  end

  def execute
    subject.execute[:status]
  end
end
