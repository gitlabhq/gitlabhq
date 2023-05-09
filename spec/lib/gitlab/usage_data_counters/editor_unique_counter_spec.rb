# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::EditorUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:user3) { build(:user, id: 3) }
  let(:project) { build(:project) }
  let(:time) { Time.zone.now }

  shared_examples 'tracks and counts action' do
    before do
      stub_application_setting(usage_ping_enabled: true)
    end

    specify do
      aggregate_failures do
        expect(track_action(author: user1, project: project)).to be_truthy
        expect(track_action(author: user2, project: project)).to be_truthy
        expect(track_action(author: user3, time: time.end_of_week - 3.days, project: project)).to be_truthy

        expect(count_unique(date_from: time.beginning_of_week, date_to: 1.week.from_now)).to eq(3)
      end
    end

    it 'track snowplow event' do
      track_action(author: user1, project: project)

      expect_snowplow_event(
        category: described_class.name,
        action: 'ide_edit',
        label: 'usage_activity_by_stage_monthly.create.action_monthly_active_users_ide_edit',
        namespace: project.namespace,
        property: event_name,
        project: project,
        user: user1,
        context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: event_name).to_h]
      )
    end

    it 'does not track edit actions if author is not present' do
      expect(track_action(author: nil, project: project)).to be_nil
    end
  end

  context 'for web IDE edit actions' do
    let(:event_name) { described_class::EDIT_BY_WEB_IDE }

    it_behaves_like 'tracks and counts action' do
      def track_action(params)
        described_class.track_web_ide_edit_action(**params)
      end

      def count_unique(params)
        described_class.count_web_ide_edit_actions(**params)
      end
    end
  end

  context 'for SFE edit actions' do
    let(:event_name) { described_class::EDIT_BY_SFE }

    it_behaves_like 'tracks and counts action' do
      def track_action(params)
        described_class.track_sfe_edit_action(**params)
      end

      def count_unique(params)
        described_class.count_sfe_edit_actions(**params)
      end
    end
  end

  context 'for snippet editor edit actions' do
    let(:event_name) { described_class::EDIT_BY_SNIPPET_EDITOR }

    it_behaves_like 'tracks and counts action' do
      def track_action(params)
        described_class.track_snippet_editor_edit_action(**params)
      end

      def count_unique(params)
        described_class.count_snippet_editor_edit_actions(**params)
      end
    end
  end
end
