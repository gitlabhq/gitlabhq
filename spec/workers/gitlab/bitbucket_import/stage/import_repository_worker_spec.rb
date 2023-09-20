# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Stage::ImportRepositoryWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  let(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketImport::StageMethods

  it 'executes the importer and enqueues ImportPullRequestsWorker' do
    expect(Gitlab::BitbucketImport::Importers::RepositoryImporter).to receive_message_chain(:new, :execute)
      .and_return(true)

    expect(Gitlab::BitbucketImport::Stage::ImportPullRequestsWorker).to receive(:perform_async).with(project.id)
      .and_return(true).once

    worker.perform(project.id)
  end
end
