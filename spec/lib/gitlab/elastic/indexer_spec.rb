require 'spec_helper'

describe Gitlab::Elastic::Indexer do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
    stub_application_setting(es_host: ['elastic-host1', 'elastic-host2'])
  end

  let(:project)  { create(:project) }
  let(:from_sha) { Gitlab::Git::BLANK_SHA }
  let(:to_sha)   { project.commit.try(:sha) }
  let(:indexer)  { described_class.new(project)  }

  let(:popen_success) { [[''], 0] }
  let(:popen_failure) { [['error'], 1] }

  let(:elastic_connection_info) do
    {
      host: current_application_settings.elasticsearch_host,
      port: current_application_settings.elasticsearch_port,
    }
  end

  context 'empty project' do
    let(:project) { create(:empty_project) }

    it 'updates the index status without running the indexing command' do
      expect_popen.never

      indexer.run

      expect_index_status(Gitlab::Git::BLANK_SHA)
    end
  end

  context 'repository has unborn head' do
    it 'updates the index status without running the indexing command' do
      allow(project.repository).to receive(:exists?).and_return(false)
      expect_popen.never

      indexer.run

      expect_index_status(Gitlab::Git::BLANK_SHA)
    end
  end

  context 'test project' do
    let(:project) { create(:project) }

    it 'runs the indexing command' do
      expect_popen.with(
        [
          File.join(Rails.root, 'bin/elastic_repo_indexer'),
          project.id.to_s,
          project.repository.path_to_repo
        ],
        nil,
        hash_including(
          'ELASTIC_CONNECTION_INFO' => elastic_connection_info.to_json,
          'RAILS_ENV'               => Rails.env,
          'FROM_SHA'                => from_sha,
          'TO_SHA'                  => to_sha
        )
      ).and_return(popen_success)

      indexer.run(from_sha, to_sha)
    end

    it 'updates the index status when the indexing is a success' do
      expect_popen.and_return(popen_success)

      indexer.run(from_sha, to_sha)

      expect_index_status(to_sha)
    end

    it 'leaves the index status untouched when indexing a non-HEAD commit' do
      expect_popen.and_return(popen_success)

      indexer.run(from_sha, project.repository.commit('HEAD~1'))

      expect(project.index_status).to be_nil
    end

    it 'leaves the index status untouched when the indexing fails' do
      expect_popen.and_return(popen_failure)

      expect { indexer.run }.to raise_error(Gitlab::Elastic::Indexer::Error)

      expect(project.index_status).to be_nil
    end
  end

  def expect_popen(*with)
    expect(Gitlab::Popen).to receive(:popen)
  end

  def expect_index_status(sha)
    status = project.index_status

    expect(status).not_to be_nil
    expect(status.indexed_at).not_to be_nil
    expect(status.last_commit).to eq(sha)
  end
end
