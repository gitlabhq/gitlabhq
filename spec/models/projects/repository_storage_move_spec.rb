# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RepositoryStorageMove, type: :model, feature_category: :source_code_management do
  it_behaves_like 'handles repository moves' do
    let_it_be_with_refind(:container) { create(:project) }

    let(:repository_storage_factory_key) { :project_repository_storage_move }
    let(:error_key) { :project }
    let(:repository_storage_worker) { Projects::UpdateRepositoryStorageWorker }
  end
end
