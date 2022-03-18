# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blobs::NotebookPresenter do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:blob) { repository.blob_at('HEAD', 'files/ruby/regex.rb') }
  let(:user) { project.first_owner }
  let(:git_blob) { blob.__getobj__ }

  subject(:presenter) { described_class.new(blob, current_user: user) }

  it 'highlight receives markdown' do
    expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: 'md')

    presenter.highlight
  end
end
