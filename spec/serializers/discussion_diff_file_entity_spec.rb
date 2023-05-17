# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiscussionDiffFileEntity do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff_refs) { commit.diff_refs }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }
  let(:entity) { described_class.new(diff_file, request: {}) }

  subject { entity.as_json }

  context 'when there is no merge request' do
    it_behaves_like 'diff file discussion entity'
  end

  context 'when there is a merge request' do
    let(:user) { create(:user) }
    let(:request) { EntityRequest.new(project: project, current_user: user) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let(:entity) { described_class.new(diff_file, request: request, merge_request: merge_request) }

    it_behaves_like 'diff file discussion entity'

    it 'exposes additional attributes' do
      expect(subject).to include(:edit_path)
    end

    it 'exposes no diff lines' do
      expect(subject).not_to include(:highlighted_diff_lines, :parallel_diff_lines)
    end
  end
end
