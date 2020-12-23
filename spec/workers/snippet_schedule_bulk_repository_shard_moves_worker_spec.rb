# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetScheduleBulkRepositoryShardMovesWorker do
  it_behaves_like 'schedules bulk repository shard moves' do
    let_it_be_with_reload(:container) { create(:snippet, :repository).tap { |snippet| snippet.create_repository } }

    let(:move_service_klass) { SnippetRepositoryStorageMove }
    let(:worker_klass) { SnippetUpdateRepositoryStorageWorker }
  end
end
