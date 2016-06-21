require "spec_helper"

describe Projects::UpdatePagesService do
  let(:project) { create :project }
  let(:pipeline) { create :ci_pipeline, project: project, sha: project.commit('HEAD').sha }
  let(:build) { create :ci_build, pipeline: pipeline, ref: 'HEAD' }
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

  def execute
    subject.execute[:status]
  end
end
