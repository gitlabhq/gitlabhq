# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blobs::NotebookPresenter do
  include RepoHelpers

  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:project, freeze: false) { create(:project, :repository) }
  let_it_be(:repository, freeze: false) { project.repository }
  let_it_be(:blob, freeze: false) { repository.blob_at('HEAD', 'files/ruby/regex.rb') }
  let_it_be(:user, freeze: false) { project.first_owner }
  let_it_be(:git_blob, freeze: false) { blob.__getobj__ }

  subject(:presenter) { described_class.new(blob, current_user: user) }

  it 'highlight receives markdown' do
    expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: 'md', used_on: :blob)

    presenter.highlight
  end
end
