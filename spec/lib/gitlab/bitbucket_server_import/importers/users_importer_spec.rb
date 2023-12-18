# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::UsersImporter, feature_category: :importers do
  let(:logger) { Gitlab::BitbucketServerImport::Logger }

  let_it_be(:project) do
    create(:project, :with_import_url, :import_started, :empty_repo,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let(:user_1) do
    BitbucketServer::Representation::User.new(
      { 'user' => { 'emailAddress' => 'email1', 'slug' => 'username1' } }
    )
  end

  let(:user_2) do
    BitbucketServer::Representation::User.new(
      { 'user' => { 'emailAddress' => 'email2', 'slug' => 'username2' } }
    )
  end

  let(:user_3) do
    BitbucketServer::Representation::User.new(
      { 'user' => { 'emailAddress' => 'email3', 'slug' => 'username3' } }
    )
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)

    allow_next_instance_of(BitbucketServer::Client) do |client|
      allow(client).to receive(:users).with('key', limit: 2, page_offset: 1).and_return([user_1, user_2])
      allow(client).to receive(:users).with('key', limit: 2, page_offset: 2).and_return([user_3])
      allow(client).to receive(:users).with('key', limit: 2, page_offset: 3).and_return([])
    end
  end

  subject(:importer) { described_class.new(project) }

  describe '#execute' do
    it 'writes the username and email to cache for every user in batches' do
      expect(logger).to receive(:info).with(hash_including(message: 'starting'))
      expect(logger).to receive(:info).with(hash_including(message: 'importing page 1 using batch size 2'))
      expect(logger).to receive(:info).with(hash_including(message: 'importing page 2 using batch size 2'))
      expect(logger).to receive(:info).with(hash_including(message: 'importing page 3 using batch size 2'))
      expect(logger).to receive(:info).with(hash_including(message: 'finished'))

      expect(Gitlab::Cache::Import::Caching).to receive(:write_multiple).and_call_original.twice

      importer.execute

      cache_key_prefix = "bitbucket_server/project/#{project.id}/source/username"
      expect(Gitlab::Cache::Import::Caching.read("#{cache_key_prefix}/username1")).to eq('email1')
      expect(Gitlab::Cache::Import::Caching.read("#{cache_key_prefix}/username2")).to eq('email2')
      expect(Gitlab::Cache::Import::Caching.read("#{cache_key_prefix}/username3")).to eq('email3')
    end
  end
end
