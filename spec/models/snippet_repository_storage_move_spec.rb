# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetRepositoryStorageMove, type: :model do
  it_behaves_like 'handles repository moves' do
    let_it_be_with_refind(:container) { create(:snippet) }

    let(:repository_storage_factory_key) { :snippet_repository_storage_move }
    let(:error_key) { :snippet }
    let(:repository_storage_worker) { nil } # TODO set to SnippetUpdateRepositoryStorageWorker after https://gitlab.com/gitlab-org/gitlab/-/issues/218991 is implemented
  end
end
