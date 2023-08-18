# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::EditorUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:user3) { build(:user, id: 3) }
  let(:project) { build(:project) }
  let(:namespace) { project.namespace }
  let(:time) { Time.zone.now }

  shared_examples 'tracks and counts action' do
    subject { track_action(author: user, project: project) }

    before do
      stub_application_setting(usage_ping_enabled: true)
    end

    specify do
      aggregate_failures do
        expect(track_action(author: user, project: project)).to be_truthy
        expect(track_action(author: user2, project: project)).to be_truthy
        expect(track_action(author: user3, project: project)).to be_truthy

        expect(count_unique(date_from: time.beginning_of_week, date_to: 1.week.from_now)).to eq(3)
      end
    end

    it_behaves_like 'internal event tracking'

    it 'does not track edit actions if author is not present' do
      expect(track_action(author: nil, project: project)).to be_nil
    end
  end

  context 'for web IDE edit actions' do
    let(:action) { described_class::EDIT_BY_WEB_IDE }

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
    let(:action) { described_class::EDIT_BY_SFE }

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
    let(:action) { described_class::EDIT_BY_SNIPPET_EDITOR }

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
