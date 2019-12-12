# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::PhabricatorImport::ProjectCreator do
  let(:user) { create(:user) }
  let(:params) do
    { path: 'new-phab-import',
      phabricator_server_url: 'http://phab.example.com',
      api_token: 'the-token' }
  end

  subject(:creator) { described_class.new(user, params) }

  describe '#execute' do
    it 'creates a project correctly and schedule an import', :sidekiq_might_not_need_inline do
      expect_next_instance_of(Gitlab::PhabricatorImport::Importer) do |importer|
        expect(importer).to receive(:execute)
      end

      project = creator.execute

      expect(project).to be_persisted
      expect(project).to be_import
      expect(project.import_type).to eq('phabricator')
      expect(project.import_data.credentials).to match(a_hash_including(api_token: 'the-token'))
      expect(project.import_data.data).to match(a_hash_including('phabricator_url' => 'http://phab.example.com'))
      expect(project.import_url).to eq(Project::UNKNOWN_IMPORT_URL)
      expect(project.namespace).to eq(user.namespace)
    end

    context 'when import params are missing' do
      let(:params) do
        { path: 'new-phab-import',
          phabricator_server_url: 'http://phab.example.com',
          api_token: '' }
      end

      it 'returns nil' do
        expect(creator.execute).to be_nil
      end
    end

    context 'when import params are invalid' do
      let(:params) do
        { path: 'new-phab-import',
          namespace_id: '-1',
          phabricator_server_url: 'http://phab.example.com',
          api_token: 'the-token' }
      end

      it 'returns an unpersisted project' do
        project = creator.execute

        expect(project).not_to be_persisted
        expect(project).not_to be_valid
      end
    end
  end
end
