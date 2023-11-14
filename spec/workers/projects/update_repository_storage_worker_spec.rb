# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateRepositoryStorageWorker, feature_category: :source_code_management do
  subject { described_class.new }

  it_behaves_like 'an update storage move worker' do
    let_it_be_with_refind(:container) { create(:project, :repository) }
    let_it_be_with_reload(:repository_storage_move) { create(:project_repository_storage_move) }

    let(:service_klass) { Projects::UpdateRepositoryStorageService }
    let(:repository_storage_move_klass) { Projects::RepositoryStorageMove }
  end
end
