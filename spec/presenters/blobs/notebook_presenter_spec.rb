# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blobs::NotebookPresenter do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }
  let_it_be(:blob) { repository.blob_at('HEAD', 'files/ruby/regex.rb') }
  let_it_be(:user) { project.first_owner }
  let_it_be(:git_blob) { blob.__getobj__ }

  subject(:presenter) { described_class.new(blob, current_user: user) }

  it 'highlight receives markdown' do
    expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: 'md', used_on: :blob)

    presenter.highlight
  end
end
