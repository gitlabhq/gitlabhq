# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::UsersImporter, feature_category: :importers do
  let(:logger) { Gitlab::BitbucketImport::Logger }

  let_it_be(:project) do
    create(:project, :with_import_url, :import_started, :empty_repo, import_source: 'workspace/repo')
  end

  let(:user_1) do
    Bitbucket::Representation::User.new(
      { 'user' => { 'account_id' => '1111:11-11', 'display_name' => 'User One', 'nickname' => 'First User' } }
    )
  end

  let(:user_2) do
    Bitbucket::Representation::User.new(
      { 'user' => { 'account_id' => '2222:22-22', 'display_name' => 'User Two' } }
    )
  end

  let(:user_3) do
    Bitbucket::Representation::User.new(
      { 'user' => { 'account_id' => '3333:33-33', 'display_name' => 'User Three' } }
    )
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)

    allow_next_instance_of(Bitbucket::Client) do |client|
      allow(client).to receive(:users).with('workspace', page_number: 1, limit: 2).and_return([user_1, user_2])
      allow(client).to receive(:users).with('workspace', page_number: 2, limit: 2).and_return([user_3])
      allow(client).to receive(:users).with('workspace', page_number: 3, limit: 2).and_return([])
    end
  end

  subject(:importer) { described_class.new(project) }

  describe '#execute' do
    it 'logs the beginning, end, and each batch' do
      expect(logger).to receive(:info).with(hash_including(message: 'starting'))
      expect(logger).to receive(:info).with(hash_including(message: 'importing page 1 using batch size 2'))
      expect(logger).to receive(:info).with(hash_including(message: 'importing page 2 using batch size 2'))
      expect(logger).to receive(:info).with(hash_including(message: 'importing page 3 using batch size 2'))
      expect(logger).to receive(:info).with(hash_including(message: 'finished'))

      importer.execute
    end

    it 'writes the nickname or name mapped to account_id to cache' do
      cache_key_prefix = "bitbucket/project/#{project.id}/source"

      importer.execute

      expect(Gitlab::Cache::Import::Caching.read("#{cache_key_prefix}/{1111:11-11}")).to eq(
        { value: 'First User', type: :name }.to_json
      )
      expect(Gitlab::Cache::Import::Caching.read("#{cache_key_prefix}/{2222:22-22}")).to eq(
        { value: 'User Two', type: :name }.to_json
      )
      expect(Gitlab::Cache::Import::Caching.read("#{cache_key_prefix}/{3333:33-33}")).to eq(
        { value: 'User Three', type: :name }.to_json
      )
    end
  end
end
