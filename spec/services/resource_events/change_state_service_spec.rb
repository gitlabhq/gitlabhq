# frozen_string_literal: true

require 'spec_helper'

describe ResourceEvents::ChangeStateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  describe '#execute' do
    context 'when resource is an issue' do
      %w[opened reopened closed locked].each do |state|
        it "creates the expected event if issue has #{state} state" do
          described_class.new(user: user, resource: issue).execute(state)

          event = issue.resource_state_events.last
          expect(event.issue).to eq(issue)
          expect(event.merge_request).to be_nil
          expect(event.state).to eq(state)
        end
      end
    end

    context 'when resource is a merge request' do
      %w[opened reopened closed locked merged].each do |state|
        it "creates the expected event if merge request has #{state} state" do
          described_class.new(user: user, resource: merge_request).execute(state)

          event = merge_request.resource_state_events.last
          expect(event.issue).to be_nil
          expect(event.merge_request).to eq(merge_request)
          expect(event.state).to eq(state)
        end
      end
    end
  end
end
