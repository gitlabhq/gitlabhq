# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::ChangeStateService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:source_commit) { create(:commit, project: project) }
  let(:source_merge_request) { create(:merge_request, source_project: project, target_project: project, target_branch: 'foo') }

  shared_examples 'a state event' do
    %w[opened reopened closed locked].each do |state|
      it "creates the expected event if resource has #{state} state" do
        described_class.new(user: user, resource: resource).execute(status: state, mentionable_source: source)

        event = resource.resource_state_events.last

        case resource
        when Issue
          expect(event.issue).to eq(resource)
          expect(event.merge_request).to be_nil
        when MergeRequest
          expect(event.issue).to be_nil
          expect(event.merge_request).to eq(resource)
        end

        expect(event.state).to eq(state)

        expect_event_source(event, source)
      end

      it "sets the created_at timestamp from the system_note_timestamp" do
        resource.system_note_timestamp = Time.at(43).utc

        described_class.new(user: user, resource: resource).execute(status: state, mentionable_source: source)
        event = resource.resource_state_events.last

        expect(event.created_at).to eq(Time.at(43).utc)
      end
    end
  end

  describe '#execute' do
    context 'when resource is an Issue' do
      context 'when no source is given' do
        it_behaves_like 'a state event' do
          let(:resource) { issue }
          let(:source) { nil }
        end
      end

      context 'when source commit is given' do
        it_behaves_like 'a state event' do
          let(:resource) { issue }
          let(:source) { source_commit }
        end
      end

      context 'when source merge request is given' do
        it_behaves_like 'a state event' do
          let(:resource) { issue }
          let(:source) { source_merge_request }
        end
      end
    end

    context 'when resource is a MergeRequest' do
      context 'when no source is given' do
        it_behaves_like 'a state event' do
          let(:resource) { merge_request }
          let(:source) { nil }
        end
      end

      context 'when source commit is given' do
        it_behaves_like 'a state event' do
          let(:resource) { merge_request }
          let(:source) { source_commit }
        end
      end

      context 'when source merge request is given' do
        it_behaves_like 'a state event' do
          let(:resource) { merge_request }
          let(:source) { source_merge_request }
        end
      end
    end
  end

  def expect_event_source(event, source)
    case source
    when MergeRequest
      expect(event.source_commit).to be_nil
      expect(event.source_merge_request).to eq(source)
    when Commit
      expect(event.source_commit).to eq(source.id)
      expect(event.source_merge_request).to be_nil
    else
      expect(event.source_merge_request).to be_nil
      expect(event.source_commit).to be_nil
    end
  end
end
