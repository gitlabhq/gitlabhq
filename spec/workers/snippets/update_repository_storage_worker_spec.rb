# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::UpdateRepositoryStorageWorker do
  subject { described_class.new }

  it_behaves_like 'an update storage move worker' do
    let_it_be_with_refind(:container) { create(:snippet, :repository) }
    let_it_be(:repository_storage_move) { create(:snippet_repository_storage_move) }

    let(:service_klass) { Snippets::UpdateRepositoryStorageService }
    let(:repository_storage_move_klass) { Snippets::RepositoryStorageMove }
  end
end
