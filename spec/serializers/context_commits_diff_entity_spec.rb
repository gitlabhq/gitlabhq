# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContextCommitsDiffEntity do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:mrcc1) { create(:merge_request_context_commit, merge_request: merge_request, sha: "cfe32cf61b73a0d5e9f13e774abde7ff789b1660") }
  let_it_be(:mrcc2) { create(:merge_request_context_commit, merge_request: merge_request, sha: "ae73cb07c9eeaf35924a10f713b364d32b2dd34f") }

  context 'as json' do
    subject { ContextCommitsDiffEntity.represent(merge_request.context_commits_diff).as_json }

    it 'exposes commits_count' do
      expect(subject[:commits_count]).to eq(2)
    end

    it 'exposes showing_context_commits_diff' do
      expect(subject).to have_key(:showing_context_commits_diff)
    end

    it 'exposes diffs_path' do
      expect(subject[:diffs_path]).to eq(Gitlab::Routing.url_helpers.diffs_project_merge_request_path(merge_request.project, merge_request, only_context_commits: true))
    end
  end
end
