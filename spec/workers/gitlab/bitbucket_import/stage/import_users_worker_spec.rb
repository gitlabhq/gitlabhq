# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Stage::ImportUsersWorker, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started, import_url: 'https://bitbucket.org')
  end

  subject(:worker) { described_class.new }

  before do
    allow_next_instance_of(Gitlab::BitbucketImport::Importers::UsersImporter) do |users_importer|
      allow(users_importer).to receive(:execute).and_return(nil)
    end

    allow(Gitlab::BitbucketImport::Stage::ImportPullRequestsWorker).to receive(:perform_async).and_return(nil)
  end

  it_behaves_like Gitlab::BitbucketImport::StageMethods

  describe '#perform' do
    let(:job_args) { [project.id] }

    it_behaves_like 'an idempotent worker'

    it 'executes the UsersImporter' do
      expect_next_instance_of(Gitlab::BitbucketImport::Importers::UsersImporter) do |users_importer|
        expect(users_importer).to receive(:execute)
      end

      worker.perform(job_args)
    end

    it 'schedules the next stage' do
      expect(Gitlab::BitbucketImport::Stage::ImportPullRequestsWorker).to receive(:perform_async)
        .with(project.id)

      worker.perform(job_args)
    end
  end
end
