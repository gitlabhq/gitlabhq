# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestSidebarExtrasEntity do
  let_it_be(:assignee) { build(:user) }
  let_it_be(:reviewer) { build(:user) }
  let_it_be(:user) { build(:user) }
  let_it_be(:project) { create :project, :repository }

  let(:params) do
    {
      source_project: project,
      target_project: project,
      assignees: [assignee],
      reviewers: [reviewer]
    }
  end

  let(:resource) do
    build(:merge_request, params)
  end

  let(:request) { double('request', current_user: user, project: project) }

  let(:entity) { described_class.new(resource, request: request).as_json }

  describe '#assignees' do
    it 'contains assignees attributes' do
      expect(entity[:assignees].count).to be 1
      expect(entity[:assignees].first.keys).to include(
        :id, :name, :username, :state, :avatar_url, :web_url, :can_merge
      )
    end
  end

  describe '#reviewers' do
    context 'when merge_request_reviewers feature is disabled' do
      it 'does not contain reviewers attributes' do
        stub_feature_flags(merge_request_reviewers: false)

        expect(entity[:reviewers]).to be_nil
      end
    end

    context 'when merge_request_reviewers feature is enabled' do
      it 'contains reviewers attributes' do
        stub_feature_flags(merge_request_reviewers: true)

        expect(entity[:reviewers].count).to be 1
        expect(entity[:reviewers].first.keys).to include(
          :id, :name, :username, :state, :avatar_url, :web_url, :can_merge
        )
      end
    end
  end
end
