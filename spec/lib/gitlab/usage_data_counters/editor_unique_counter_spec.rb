# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::EditorUniqueCounter, :clean_gitlab_redis_shared_state do
  shared_examples 'tracks and counts action' do
    let(:user1) { build(:user, id: 1) }
    let(:user2) { build(:user, id: 2) }
    let(:user3) { build(:user, id: 3) }
    let(:time) { Time.zone.now }

    specify do
      stub_application_setting(usage_ping_enabled: true)

      aggregate_failures do
        expect(track_action(author: user1)).to be_truthy
        expect(track_action(author: user1)).to be_truthy
        expect(track_action(author: user2)).to be_truthy
        expect(track_action(author: user3, time: time - 3.days)).to be_truthy

        expect(count_unique(date_from: time, date_to: Date.today)).to eq(2)
        expect(count_unique(date_from: time - 5.days, date_to: Date.tomorrow)).to eq(3)
      end
    end

    context 'when feature flag track_editor_edit_actions is disabled' do
      it 'does not track edit actions' do
        stub_feature_flags(track_editor_edit_actions: false)

        expect(track_action(author: user1)).to be_nil
      end
    end
  end

  context 'for web IDE edit actions' do
    it_behaves_like 'tracks and counts action' do
      def track_action(params)
        described_class.track_web_ide_edit_action(params)
      end

      def count_unique(params)
        described_class.count_web_ide_edit_actions(params)
      end
    end
  end

  context 'for SFE edit actions' do
    it_behaves_like 'tracks and counts action' do
      def track_action(params)
        described_class.track_sfe_edit_action(params)
      end

      def count_unique(params)
        described_class.count_sfe_edit_actions(params)
      end
    end
  end

  context 'for snippet editor edit actions' do
    it_behaves_like 'tracks and counts action' do
      def track_action(params)
        described_class.track_snippet_editor_edit_action(params)
      end

      def count_unique(params)
        described_class.count_snippet_editor_edit_actions(params)
      end
    end
  end
end
