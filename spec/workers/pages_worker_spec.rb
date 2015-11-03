require "spec_helper"

describe PagesWorker do
  let(:project) { create :project }
  let(:commit) { create :ci_commit, project: project, sha: project.commit('HEAD').sha }
  let(:build) { create :ci_build, commit: commit, ref: 'HEAD' }
  let(:worker) { PagesWorker.new }
  let(:file) { fixture_file_upload(Rails.root + 'spec/fixtures/pages.tar.gz', 'application/octet-stream') }
  let(:empty_file) { fixture_file_upload(Rails.root + 'spec/fixtures/pages_empty.tar.gz', 'application/octet-stream') }
  let(:invalid_file) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'application/octet-stream') }

  before do
    project.remove_pages
  end

  context 'for valid file' do
    before { build.update_attributes(artifacts_file: file) }

    it 'succeeds' do
      expect(project.pages_url).to be_nil
      expect(worker.perform(build.id)).to be_truthy
      expect(project.pages_url).to_not be_nil
    end

    it 'limits pages size' do
      stub_application_setting(max_pages_size: 1)
      expect(worker.perform(build.id)).to_not be_truthy
    end

    it 'removes pages after destroy' do
      expect(project.pages_url).to be_nil
      expect(worker.perform(build.id)).to be_truthy
      expect(project.pages_url).to_not be_nil
      project.destroy
      expect(Dir.exist?(project.public_pages_path)).to be_falsey
    end
  end

  it 'fails if no artifacts' do
    expect(worker.perform(build.id)).to_not be_truthy
  end

  it 'fails for empty file fails' do
    build.update_attributes(artifacts_file: empty_file)
    expect(worker.perform(build.id)).to_not be_truthy
  end

  it 'fails for invalid archive' do
    build.update_attributes(artifacts_file: invalid_file)
    expect(worker.perform(build.id)).to_not be_truthy
  end

  it 'fails if sha on branch is not latest' do
    commit.update_attributes(sha: 'old_sha')
    build.update_attributes(artifacts_file: file)
    expect(worker.perform(build.id)).to_not be_truthy
  end
end
