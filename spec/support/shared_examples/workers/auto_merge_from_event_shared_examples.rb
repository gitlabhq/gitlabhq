# frozen_string_literal: true

RSpec.shared_examples 'process auto merge from event worker' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, merge_user: user) }
  let(:merge_request_id) { merge_request.id }

  let(:data) { { current_user_id: user.id, merge_request_id: merge_request_id } }

  it_behaves_like 'subscribes to event' do
    it 'calls AutoMergeService' do
      expect_next_instance_of(
        AutoMergeService,
        project, user
      ) do |service|
        expect(service).to receive(:process).with(merge_request)
      end

      consume_event(subscriber: described_class, event: event)
    end

    context 'when the merge request does not exist' do
      let(:merge_request_id) { -1 }

      it 'logs and does not call AutoMergeService' do
        expect(Sidekiq.logger).to receive(:info).with(
          hash_including('message' => 'Merge request not found.', 'merge_request_id' => merge_request_id)
        )
        expect(AutoMergeService).not_to receive(:new)

        expect { consume_event(subscriber: described_class, event: event) }
          .not_to raise_exception
      end
    end

    context 'when feature flag "merge_when_checks_pass" is disabled' do
      before do
        stub_feature_flags(merge_when_checks_pass: false)
      end

      it "doesn't call AutoMergeService" do
        expect(AutoMergeService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end
  end
end
