require "spec_helper"

describe Projects::UpdatePagesService do
  let(:project) { create :project }
  let(:commit) { create :ci_commit, project: project, sha: project.commit('HEAD').sha }
  let(:build) { create :ci_build, commit: commit, ref: 'HEAD' }
  let(:file) { fixture_file_upload(Rails.root + 'spec/fixtures/pages.tar.gz', 'application/octet-stream') }
  let(:empty_file) { fixture_file_upload(Rails.root + 'spec/fixtures/pages_empty.tar.gz', 'application/octet-stream') }
  let(:invalid_file) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'application/octet-stream') }
  
  subject { described_class.new(project, build) }

  before do
    project.remove_pages
  end

  context 'for valid file' do
    before { build.update_attributes(artifacts_file: file) }

    it 'succeeds' do
      expect(project.pages_url).to be_nil
      expect(execute).to eq(:success)
      expect(project.pages_url).to_not be_nil
    end

    it 'limits pages size' do
      stub_application_setting(max_pages_size: 1)
      expect(execute).to_not eq(:success)
    end

    it 'removes pages after destroy' do
      expect(PagesWorker).to receive(:perform_in)
      expect(project.pages_url).to be_nil
      expect(execute).to eq(:success)
      expect(project.pages_url).to_not be_nil
      project.destroy
      expect(Dir.exist?(project.public_pages_path)).to be_falsey
    end
  end

  it 'fails to remove project pages when no pages is deployed' do
    expect(PagesWorker).to_not receive(:perform_in)
    expect(project.pages_url).to be_nil
    project.destroy
  end

  it 'fails if no artifacts' do
    expect(execute).to_not eq(:success)
  end

  it 'fails for empty file fails' do
    build.update_attributes(artifacts_file: empty_file)
    expect(execute).to_not eq(:success)
  end

  it 'fails for invalid archive' do
    build.update_attributes(artifacts_file: invalid_file)
    expect(execute).to_not eq(:success)
  end

  it 'fails if sha on branch is not latest' do
    commit.update_attributes(sha: 'old_sha')
    build.update_attributes(artifacts_file: file)
    expect(execute).to_not eq(:success)
  end
  
  def execute
    subject.execute[:status]
  end
end
