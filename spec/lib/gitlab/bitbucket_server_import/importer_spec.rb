require 'spec_helper'

describe Gitlab::BitbucketServerImport::Importer do
  include ImportSpecHelper

  let(:project) { create(:project, import_url: 'http://my-bitbucket') }

  subject { described_class.new(project) }

  before do
    data = project.create_or_update_import_data(
      data: { project_key: 'TEST', repo_slug: 'rouge' },
      credentials: { base_uri: 'http://my-bitbucket', user: 'bitbucket', password: 'test' }
    )
    data.save
    project.save
  end

  describe '#import_repository' do
    before do
      expect(subject).to receive(:import_pull_requests)
      expect(subject).to receive(:delete_temp_branches)
    end

    it 'adds a remote' do
      expect(project.repository).to receive(:fetch_as_mirror)
                                     .with('http://bitbucket:test@my-bitbucket',
                                           refmap: [:heads, :tags, '+refs/pull-requests/*/to:refs/merge-requests/*/head'],
                                           remote_name: 'bitbucket_server')

      subject.execute
    end
  end

  describe '#import_pull_requests' do

  end

  describe '#delete_temp_branches' do

  end
end
