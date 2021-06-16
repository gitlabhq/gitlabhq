# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ScheduleBulkRepositoryShardMovesService do
  it_behaves_like 'moves repository shard in bulk' do
    let_it_be_with_reload(:container) { create(:project, :repository) }

    let(:move_service_klass) { Projects::RepositoryStorageMove }
    let(:bulk_worker_klass) { ::Projects::ScheduleBulkRepositoryShardMovesWorker }
  end
end
