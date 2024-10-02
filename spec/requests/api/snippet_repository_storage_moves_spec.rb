# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::SnippetRepositoryStorageMoves, :with_license, feature_category: :gitaly do
  it_behaves_like 'repository_storage_moves API', 'snippets' do
    let_it_be(:container) { create(:project_snippet, :repository).tap { |snippet| snippet.create_repository } }
    let_it_be(:storage_move) { create(:snippet_repository_storage_move, :scheduled, container: container) }
    let(:repository_storage_move_factory) { :snippet_repository_storage_move }
    let(:bulk_worker_klass) { Snippets::ScheduleBulkRepositoryShardMovesWorker }
  end
end
