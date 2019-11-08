# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::IssuableMetadata do
  let(:user)     { create(:user) }
  let!(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace) }

  subject { Class.new { include Gitlab::IssuableMetadata }.new }

  it 'returns an empty Hash if an empty collection is provided' do
    expect(subject.issuable_meta_data(Issue.none, 'Issue', user)).to eq({})
  end

  it 'raises an error when given a collection with no limit' do
    expect { subject.issuable_meta_data(Issue.all, 'Issue', user) }.to raise_error(/must have a limit/)
  end

  context 'issues' do
    let!(:issue) { create(:issue, author: user, project: project) }
    let!(:closed_issue) { create(:issue, state: :closed, author: user, project: project) }
    let!(:downvote) { create(:award_emoji, :downvote, awardable: closed_issue) }
    let!(:upvote) { create(:award_emoji, :upvote, awardable: issue) }
    let!(:merge_request) { create(:merge_request, :simple, author: user, assignees: [user], source_project: project, target_project: project, title: "Test") }
    let!(:closing_issues) { create(:merge_requests_closing_issues, issue: issue, merge_request: merge_request) }

    it 'aggregates stats on issues' do
      data = subject.issuable_meta_data(Issue.all.limit(10), 'Issue', user)

      expect(data.count).to eq(2)
      expect(data[issue.id].upvotes).to eq(1)
      expect(data[issue.id].downvotes).to eq(0)
      expect(data[issue.id].user_notes_count).to eq(0)
      expect(data[issue.id].merge_requests_count).to eq(1)

      expect(data[closed_issue.id].upvotes).to eq(0)
      expect(data[closed_issue.id].downvotes).to eq(1)
      expect(data[closed_issue.id].user_notes_count).to eq(0)
      expect(data[closed_issue.id].merge_requests_count).to eq(0)
    end
  end

  context 'merge requests' do
    let!(:merge_request) { create(:merge_request, :simple, author: user, assignees: [user], source_project: project, target_project: project, title: "Test") }
    let!(:merge_request_closed) { create(:merge_request, state: "closed", source_project: project, target_project: project, title: "Closed Test") }
    let!(:downvote) { create(:award_emoji, :downvote, awardable: merge_request) }
    let!(:upvote) { create(:award_emoji, :upvote, awardable: merge_request) }
    let!(:note) { create(:note_on_merge_request, author: user, project: project, noteable: merge_request, note: "a comment on a MR") }

    it 'aggregates stats on merge requests' do
      data = subject.issuable_meta_data(MergeRequest.all.limit(10), 'MergeRequest', user)

      expect(data.count).to eq(2)
      expect(data[merge_request.id].upvotes).to eq(1)
      expect(data[merge_request.id].downvotes).to eq(1)
      expect(data[merge_request.id].user_notes_count).to eq(1)
      expect(data[merge_request.id].merge_requests_count).to eq(0)

      expect(data[merge_request_closed.id].upvotes).to eq(0)
      expect(data[merge_request_closed.id].downvotes).to eq(0)
      expect(data[merge_request_closed.id].user_notes_count).to eq(0)
      expect(data[merge_request_closed.id].merge_requests_count).to eq(0)
    end
  end
end
