# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitUserMention, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'model with associated note' do
    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:commit) { project.commit }
    let_it_be(:note) { create(:note_on_commit, commit_id: commit.id, project: project) }

    let(:record_attrs) { { commit_id: commit.id, note_id: note.id } }
  end

  it_behaves_like 'has user mentions' do
    let_it_be(:mentionable_key) { 'commit_id' }
    let_it_be(:mentionable) { create(:commit, project: create(:project), commit_message: 'test') }
  end
end
