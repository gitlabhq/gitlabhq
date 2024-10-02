# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::ScheduleBulkRepositoryShardMovesService, feature_category: :source_code_management do
  it_behaves_like 'moves repository shard in bulk' do
    let_it_be_with_reload(:container) { create(:personal_snippet, :repository) }
    let(:expected_class) { Snippet }

    let(:move_service_klass) { Snippets::RepositoryStorageMove }
    let(:bulk_worker_klass) { ::Snippets::ScheduleBulkRepositoryShardMovesWorker }
  end
end
