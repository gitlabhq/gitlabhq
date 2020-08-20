# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::Commit do
  let(:project) { create(:project, :repository) }

  it_behaves_like 'diff statistics' do
    let(:collection_default_args) do
      { diff_options: {} }
    end

    let(:diffable) { project.commit }
    let(:stub_path) { 'bar/branch-test.txt' }
  end

  it_behaves_like 'unfoldable diff' do
    let(:diffable) { project.commit }
  end
end
