# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::EditorUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:user3) { build(:user, id: 3) }
  let(:time) { Time.zone.now }

  shared_examples 'tracks and counts action' do
    before do
      stub_application_setting(usage_ping_enabled: true)
    end

    specify do
      aggregate_failures do
        expect(track_action(author: user1)).to be_truthy
        expect(track_action(author: user1)).to be_truthy
        expect(track_action(author: user2)).to be_truthy
        expect(track_action(author: user3, time: time - 3.days)).to be_truthy

        expect(count_unique(date_from: time, date_to: Date.today)).to eq(2)
        expect(count_unique(date_from: time - 5.days, date_to: Date.tomorrow)).to eq(3)
      end
    end

    it 'does not track edit actions if author is not present' do
      expect(track_action(author: nil)).to be_nil
    end
  end

  context 'for web IDE edit actions' do
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
    it_behaves_like 'tracks and counts action' do
      def track_action(params)
        described_class.track_snippet_editor_edit_action(**params)
      end

      def count_unique(params)
        described_class.count_snippet_editor_edit_actions(**params)
      end
    end
  end

  context 'for SSE edit actions' do
    it_behaves_like 'tracks and counts action' do
      def track_action(params)
        described_class.track_sse_edit_action(**params)
      end

      def count_unique(params)
        described_class.count_sse_edit_actions(**params)
      end
    end
  end

  it 'can return the count of actions per user deduplicated' do
    described_class.track_web_ide_edit_action(author: user1)
    described_class.track_snippet_editor_edit_action(author: user1)
    described_class.track_sfe_edit_action(author: user1)
    described_class.track_web_ide_edit_action(author: user2, time: time - 2.days)
    described_class.track_web_ide_edit_action(author: user3, time: time - 3.days)
    described_class.track_snippet_editor_edit_action(author: user3, time: time - 3.days)
    described_class.track_sfe_edit_action(author: user3, time: time - 3.days)

    expect(described_class.count_edit_using_editor(date_from: time, date_to: Date.today)).to eq(1)
    expect(described_class.count_edit_using_editor(date_from: time - 5.days, date_to: Date.tomorrow)).to eq(3)
  end
end
