require "spec_helper"

describe Projects::UpdatePagesService do
  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha) }
  let(:build) { create(:ci_build, pipeline: pipeline, ref: 'HEAD') }
  let(:invalid_file) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png') }

  subject { described_class.new(project, build) }

  before do
    project.remove_pages
  end

  %w(tar.gz zip).each do |format|
    context "for valid #{format}" do
      let(:file) { fixture_file_upload(Rails.root + "spec/fixtures/pages.#{format}") }
      let(:empty_file) { fixture_file_upload(Rails.root + "spec/fixtures/pages_empty.#{format}") }
      let(:metadata) do
        filename = Rails.root + "spec/fixtures/pages.#{format}.meta"
        fixture_file_upload(filename) if File.exist?(filename)
      end

      before do
        build.update_attributes(artifacts_file: file)
        build.update_attributes(artifacts_metadata: metadata)
      end

      describe 'pages artifacts' do
        context 'with expiry date' do
          before do
            build.artifacts_expire_in = "2 days"
          end

          it "doesn't delete artifacts" do
            expect(execute).to eq(:success)

            expect(build.reload.artifacts_file?).to eq(true)
          end
        end

        context 'without expiry date' do
          it "does delete artifacts" do
            expect(execute).to eq(:success)

            expect(build.reload.artifacts_file?).to eq(false)
          end
        end
      end

      it 'succeeds' do
        expect(project.pages_deployed?).to be_falsey
        expect(execute).to eq(:success)
        expect(project.pages_deployed?).to be_truthy
      end

      it 'limits pages size' do
        stub_application_setting(max_pages_size: 1)
        expect(execute).not_to eq(:success)
      end

      it 'removes pages after destroy' do
        expect(PagesWorker).to receive(:perform_in)
        expect(project.pages_deployed?).to be_falsey
        expect(execute).to eq(:success)
        expect(project.pages_deployed?).to be_truthy
        project.destroy
        expect(project.pages_deployed?).to be_falsey
      end

      it 'fails if sha on branch is not latest' do
        pipeline.update_attributes(sha: 'old_sha')
        build.update_attributes(artifacts_file: file)
        expect(execute).not_to eq(:success)
      end

      it 'fails for empty file fails' do
        build.update_attributes(artifacts_file: empty_file)
        expect(execute).not_to eq(:success)
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
    build.update_attributes(artifacts_file: invalid_file)
    expect(execute).not_to eq(:success)
  end

  describe 'maximum pages artifacts size' do
    let(:metadata) { spy('metadata') }

    before do
      file = fixture_file_upload(Rails.root + 'spec/fixtures/pages.zip')
      metafile = fixture_file_upload(Rails.root + 'spec/fixtures/pages.zip.meta')

      build.update_attributes(artifacts_file: file)
      build.update_attributes(artifacts_metadata: metafile)

      allow(build).to receive(:artifacts_metadata_entry)
        .and_return(metadata)
    end

    shared_examples 'pages size limit exceeded' do
      it 'limits the maximum size of gitlab pages' do
        subject.execute

        expect(deploy_status.description)
          .to match(/artifacts for pages are too large/)
        expect(deploy_status).to be_job_failure
      end
    end

    context 'when maximum pages size is set to zero' do
      before do
        stub_application_setting(max_pages_size: 0)
      end

      context 'when page size does not exceed internal maximum' do
        before do
          allow(metadata).to receive(:total_size).and_return(200.megabytes)
        end

        it 'updates pages correctly' do
          subject.execute

          expect(deploy_status.description).not_to be_present
        end
      end

      context 'when pages size does exceed internal maximum' do
        before do
          allow(metadata).to receive(:total_size).and_return(2.terabytes)
        end

        it_behaves_like 'pages size limit exceeded'
      end
    end

    context 'when pages size is greater than max size setting' do
      before do
        stub_application_setting(max_pages_size: 200)
        allow(metadata).to receive(:total_size).and_return(201.megabytes)
      end

      it_behaves_like 'pages size limit exceeded'
    end

    context 'when max size setting is greater than internal max size' do
      before do
        stub_application_setting(max_pages_size: 3.terabytes / 1.megabyte)
        allow(metadata).to receive(:total_size).and_return(2.terabytes)
      end

      it_behaves_like 'pages size limit exceeded'
    end
  end

  def deploy_status
    GenericCommitStatus.find_by(name: 'pages:deploy')
  end

  def execute
    subject.execute[:status]
  end
end
