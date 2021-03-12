# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::ScheduleBulkRepositoryShardMovesService do
  it_behaves_like 'moves repository shard in bulk' do
    let_it_be_with_reload(:container) { create(:snippet, :repository) }

    let(:move_service_klass) { Snippets::RepositoryStorageMove }
    let(:bulk_worker_klass) { ::Snippets::ScheduleBulkRepositoryShardMovesWorker }
  end
end
