# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::ScheduleBulkRepositoryShardMovesWorker, feature_category: :gitaly do
  it_behaves_like 'schedules bulk repository shard moves' do
    let_it_be_with_reload(:container) do
      create(:project_snippet, :repository).tap { |snippet| snippet.create_repository }
    end

    let(:move_service_klass) { Snippets::RepositoryStorageMove }
    let(:worker_klass) { Snippets::UpdateRepositoryStorageWorker }
  end
end
