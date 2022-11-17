# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'forked project import' do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let!(:project_with_repo) { create(:project, :repository, name: 'test-repo-restorer', path: 'test-repo-restorer') }
  let!(:project) { create(:project, name: 'test-repo-restorer-no-repo', path: 'test-repo-restorer-no-repo') }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:shared) { project.import_export_shared }
  let(:forked_from_project) { create(:project, :repository) }
  let(:forked_project) { fork_project(project_with_repo, nil, repository: true) }
  let(:repo_saver) { Gitlab::ImportExport::RepoSaver.new(exportable: project_with_repo, shared: shared) }
  let(:bundle_path) { File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename) }

  let(:repo_restorer) do
    Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: bundle_path, shared: shared, importable: project)
  end

  let!(:merge_request) do
    create(:merge_request, source_project: forked_project, target_project: project_with_repo)
  end

  let(:saver) do
    Gitlab::ImportExport::Project::TreeSaver.new(project: project_with_repo, current_user: user, shared: shared)
  end

  let(:restorer) do
    Gitlab::ImportExport::Project::TreeRestorer.new(user: user, shared: shared, project: project)
  end

  before do
    stub_feature_flags(project_export_as_ndjson: false)

    allow_next_instance_of(Gitlab::ImportExport) do |instance|
      allow(instance).to receive(:storage_path).and_return(export_path)
    end

    saver.save # rubocop:disable Rails/SaveBang
    repo_saver.save # rubocop:disable Rails/SaveBang

    repo_restorer.restore
    restorer.restore
  end

  after do
    FileUtils.rm_rf(export_path)
    project_with_repo.repository.remove
    project.repository.remove
  end

  it 'can access the MR', :sidekiq_might_not_need_inline do
    project.merge_requests.first.fetch_ref!

    expect(project.repository.ref_exists?('refs/merge-requests/1/head')).to be_truthy
  end
end
