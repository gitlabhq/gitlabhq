# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiffRefsEntity, feature_category: :code_review_workflow do
  let(:diff_refs) { Gitlab::Diff::DiffRefs.new(base_sha: 'abc', start_sha: 'def', head_sha: 'ghi') }

  subject(:serialized) { described_class.new(diff_refs).as_json }

  it 'exposes base_sha, start_sha, and head_sha' do
    expect(serialized).to include(base_sha: 'abc', start_sha: 'def', head_sha: 'ghi')
  end
end
