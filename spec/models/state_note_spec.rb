# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StateNote, feature_category: :team_planning do
  describe '.from_event' do
    let_it_be(:author) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:noteable) { create(:issue, author: author, project: project) }

    let(:event) { create(:resource_state_event, **event_args) }

    ResourceStateEvent.states.each do |state, _value|
      context "with event state #{state}" do
        let(:event_args) { { issue: noteable, state: state, created_at: '2020-02-05' } }

        subject { described_class.from_event(event, resource: noteable, resource_parent: project) }

        it_behaves_like 'a synthetic note', state == 'reopened' ? 'opened' : state

        it 'contains the expected values' do
          expect(subject.author).to eq(author)
          expect(subject.created_at).to eq(event.created_at)
          expect(subject.updated_at).to eq(event.created_at)
          expect(subject.note).to eq(state)
        end
      end
    end

    context 'with a mentionable source' do
      subject { described_class.from_event(event, resource: noteable, resource_parent: project) }

      context 'with a commit' do
        let(:commit) { create(:commit, project: project) }
        let(:event_args) { { issue: noteable, state: :closed, created_at: '2020-02-05', source_commit: commit.id } }

        it 'contains the expected values' do
          expect(subject.author).to eq(author)
          expect(subject.created_at).to eq(event.created_at)
          expect(subject.updated_at).to eq(event.created_at)
          expect(subject.note).to eq("closed with commit #{commit.id}")
        end
      end

      context 'with a merge request' do
        let(:merge_request) { create(:merge_request, source_project: project) }
        let(:event_args) { { issue: noteable, state: :closed, created_at: '2020-02-05', source_merge_request: merge_request } }

        it 'contains the expected values' do
          expect(subject.author).to eq(author)
          expect(subject.created_at).to eq(event.created_at)
          expect(subject.updated_at).to eq(event.created_at)
          expect(subject.note).to eq("closed with merge request !#{merge_request.iid}")
        end
      end

      context 'when noteable is a merge request', feature_category: :code_review_workflow do
        let(:noteable) { create(:merge_request, source_project: project, author: author) }

        context 'when merged by a commit' do
          let(:source_commit) { create(:commit, project: project) }
          let(:event_args) { { merge_request: noteable, state: :merged, created_at: '2020-02-05', source_commit: source_commit.id, user: author } }

          it 'contains the expected values' do
            expect(subject.author).to eq(author)
            expect(subject.created_at).to eq(event.created_at)
            expect(subject.updated_at).to eq(event.created_at)
            expect(subject.note).to eq("merged manually")
          end
        end

        context 'when merged by another merge_request' do
          let(:merge_request) { create(:merge_request, :simple, source_project: project) }
          let(:event_args) { { merge_request: noteable, state: :merged, created_at: '2020-02-05', source_merge_request: merge_request, user: author } }

          it 'contains the expected values' do
            expect(subject.author).to eq(author)
            expect(subject.created_at).to eq(event.created_at)
            expect(subject.updated_at).to eq(event.created_at)
            expect(subject.note).to eq("merged with merge request !#{merge_request.iid}")
          end
        end
      end

      context 'when closed by error tracking' do
        let(:event_args) { { issue: noteable, state: :closed, created_at: '2020-02-05', close_after_error_tracking_resolve: true } }

        it 'contains the expected values' do
          expect(subject.author).to eq(author)
          expect(subject.created_at).to eq(event.created_at)
          expect(subject.updated_at).to eq(event.created_at)
          expect(subject.note).to eq('resolved the corresponding error and closed the issue')
        end
      end

      context 'when closed by promotheus alert' do
        let(:event_args) { { issue: noteable, state: :closed, created_at: '2020-02-05', close_auto_resolve_prometheus_alert: true } }

        it 'contains the expected values' do
          expect(subject.author).to eq(author)
          expect(subject.created_at).to eq(event.created_at)
          expect(subject.updated_at).to eq(event.created_at)
          expect(subject.note).to eq('automatically closed this incident because the alert resolved')
        end
      end
    end
  end
end
