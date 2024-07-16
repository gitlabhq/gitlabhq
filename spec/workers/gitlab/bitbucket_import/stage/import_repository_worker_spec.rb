# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Stage::ImportRepositoryWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started, import_url: 'https://bitbucket.org') }
  let(:importer_double) { instance_double(Gitlab::BitbucketImport::Importers::RepositoryImporter) }

  subject(:worker) { described_class.new }

  before do
    allow(Gitlab::BitbucketImport::Importers::RepositoryImporter).to receive(:new).and_return(importer_double)
    allow(importer_double).to receive(:execute).and_return(true)
  end

  it_behaves_like Gitlab::BitbucketImport::StageMethods

  it 'executes the importer' do
    expect(importer_double).to receive(:execute)

    worker.perform(project.id)
  end

  it 'aborts the whole import when the importer fails' do
    exception = StandardError.new('Error')
    allow(worker).to receive(:import).and_raise(exception)

    expect { worker.perform(project.id) }
      .to raise_error(exception)

    expect(project.import_state.reload.status).to eq('failed')

    expect(project.import_failures).not_to be_empty
  end

  context 'when the FF is enabled' do
    it 'executes the importer and enqueues ImportUsersWorker' do
      expect(Gitlab::BitbucketImport::Stage::ImportUsersWorker).to receive(:perform_async).with(project.id)
        .and_return(true).once

      worker.perform(project.id)
    end
  end
end
