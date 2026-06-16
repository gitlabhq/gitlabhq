# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::Notifications, feature_category: :team_planning do
  it_behaves_like 'work item widget entity parity',
    described_class,
    Types::WorkItems::Widgets::NotificationsType

  describe '#as_json' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:work_item) { create(:work_item, author: other_user) }

    let(:widget) { WorkItems::Widgets::Notifications.new(work_item) }
    let(:cache) { {} }
    let(:options) { { current_user: user, notifications_subscriptions: cache } }

    subject(:representation) { described_class.new(widget, options).as_json }

    context 'when current_user is nil' do
      let(:options) { { current_user: nil, notifications_subscriptions: cache } }

      it 'exposes subscribed as false' do
        expect(representation).to include(subscribed: false)
      end
    end

    context 'with a cached subscription that is subscribed' do
      let(:cache) { { work_item.id => instance_double(Subscription, subscribed: true) } }

      it 'returns true' do
        expect(representation).to include(subscribed: true)
      end
    end

    context 'with a cached subscription that is explicitly unsubscribed' do
      let(:cache) { { work_item.id => instance_double(Subscription, subscribed: false) } }

      it 'wins over the author/assignee fallback' do
        # Even if the user would otherwise be implicitly subscribed (e.g. as the author),
        # an explicit unsubscribe row must take precedence.
        allow(work_item).to receive(:author_id).and_return(user.id)

        expect(representation).to include(subscribed: false)
      end
    end

    context 'when no explicit subscription is cached' do
      it 'returns true when the user is the work item author' do
        allow(work_item).to receive(:author_id).and_return(user.id)

        expect(representation).to include(subscribed: true)
      end

      it 'returns true when the user is an assignee' do
        ia = instance_double(IssueAssignee, user_id: user.id)
        allow(work_item).to receive(:issue_assignees).and_return([ia])

        expect(representation).to include(subscribed: true)
      end

      it 'returns false when the user is neither author nor assignee' do
        expect(representation).to include(subscribed: false)
      end

      it 'does not call participant? on the listing path', :aggregate_failures do
        # The listing render path doesn't set notifications_allow_participant_fallback, so the entity must skip the
        # expensive participant? lookup to avoid the per-item notes / award_emoji N+1
        expect(work_item).not_to receive(:participant?)
        expect(work_item).not_to receive(:subscribed?)

        representation
      end
    end

    context 'with the participant? fallback opt-in' do
      let(:options) { super().merge(notifications_allow_participant_fallback: true) }

      it 'returns true when the user is a participant via notes / mentions', :aggregate_failures do
        expect(work_item).to receive(:participant?).with(user).and_return(true)

        expect(representation).to include(subscribed: true)
      end

      it 'returns false when the user is not a participant', :aggregate_failures do
        expect(work_item).to receive(:participant?).with(user).and_return(false)

        expect(representation).to include(subscribed: false)
      end

      it 'short-circuits before participant? when the user is the author', :aggregate_failures do
        allow(work_item).to receive(:author_id).and_return(user.id)
        expect(work_item).not_to receive(:participant?)

        expect(representation).to include(subscribed: true)
      end
    end

    context 'when no cache is provided' do
      let(:options) { { current_user: user } }

      it 'still applies the author/assignee fallback' do
        allow(work_item).to receive(:author_id).and_return(user.id)

        expect(representation).to include(subscribed: true)
      end

      it 'returns false when the user is neither author nor assignee' do
        expect(representation).to include(subscribed: false)
      end
    end
  end
end
