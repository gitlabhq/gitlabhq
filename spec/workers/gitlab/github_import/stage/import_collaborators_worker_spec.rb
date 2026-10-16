# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportCollaboratorsWorker, feature_category: :importers do
  let_it_be_with_reload(:project) { create(:project, :in_group, :github_import) }

  let(:settings) { Gitlab::GithubImport::Settings.new(project) }
  let(:stage_enabled) { true }
  let(:importer) { instance_double(Gitlab::GithubImport::Importer::CollaboratorsImporter) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    let(:push_rights_granted) { true }

    before do
      project.build_or_assign_import_data(data: { optional_stages: { collaborators_import: stage_enabled } }).save!

      allow(client).to receive(:repository).with(project.import_source)
        .and_return({ permissions: { push: push_rights_granted } })
    end

    context 'when user has push access for this repo' do
      it 'imports all collaborators' do
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)
        expect(importer).to receive(:execute).and_return(waiter)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, { '123' => 2 }, 'issues_and_diff_notes')

        worker.import(client, project)
      end
    end

    context 'when user do not have push access for this repo' do
      let(:push_rights_granted) { false }

      it 'skips stage and logs no push access' do
        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter).not_to receive(:new)

        expect(Gitlab::GithubImport::Logger).to receive(:warn)
          .with(a_hash_including(
            project_id: project.id,
            Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id,
            importer: 'Importer::CollaboratorsImporter',
            message: 'no push access rights to fetch collaborators'
          ))

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, {}, 'issues_and_diff_notes')

        worker.import(client, project)
      end
    end

    context 'when stage is disabled' do
      let(:stage_enabled) { false }

      it 'skips collaborators import and calls next stage' do
        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter).not_to receive(:new)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, {}, 'issues_and_diff_notes')

        worker.import(client, project)
      end
    end

    context 'when importing into a personal namespace' do
      let_it_be_with_reload(:project) { create(:project, :github_import) }

      it 'skips collaborators import and calls next stage' do
        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter).not_to receive(:new)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, {}, 'issues_and_diff_notes')

        worker.import(client, project)
      end
    end
  end

  describe '#perform with an expiring OAuth token', :freeze_time do
    let(:token_url) { 'https://github.com/login/oauth/access_token' }
    let(:config) do
      Gitlab::Configs::Options.build(
        'app_id' => 'app-id',
        'app_secret' => 'app-secret',
        'args' => { 'client_options' => { 'site' => 'https://api.github.com', 'token_url' => token_url } }
      )
    end

    before do
      project.update!(import_source: 'foo/bar')
      project.build_or_assign_import_data(
        data: { optional_stages: { collaborators_import: true } },
        credentials: { user: 'ghu_old', refresh_token: 'ghr_old', expires_at: 1.hour.from_now.to_i }
      ).save!

      allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(config)
      allow_next_instance_of(Gitlab::GithubImport::Client) do |client|
        allow(client).to receive(:requests_remaining?).and_return(true)
      end

      stub_request(:post, token_url).to_return(
        status: 200,
        body: { access_token: 'ghu_new', refresh_token: 'ghr_new', expires_in: 28800 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      stub_request(:get, 'https://api.github.com/repos/foo/bar')
        .with(headers: { 'Authorization' => /ghu_old/ })
        .to_return(status: 401)
      stub_request(:get, 'https://api.github.com/repos/foo/bar')
        .with(headers: { 'Authorization' => /ghu_new/ })
        .to_return(
          status: 200,
          body: { permissions: { push: true } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'refreshes the token after a 401 and finishes the stage' do
      allow(Gitlab::GithubImport::Importer::CollaboratorsImporter).to receive(:new)
        .and_return(instance_double(Gitlab::GithubImport::Importer::CollaboratorsImporter,
          execute: Gitlab::JobWaiter.new(0, '123')))

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 0 }, 'issues_and_diff_notes')

      worker.perform(project.id)

      expect(project.import_data.reload.credentials).to include(user: 'ghu_new', refresh_token: 'ghr_new')
    end
  end
end
