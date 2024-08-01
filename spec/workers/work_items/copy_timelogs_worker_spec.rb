# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CopyTimelogsWorker, type: :worker, feature_category: :team_planning do
  let_it_be(:from_issue) { create(:issue) }
  let_it_be(:to_issue) { create(:issue) }
  let_it_be(:timelog) { create(:timelog, issue: from_issue) }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  describe '#perform' do
    context 'when both issues exist and conditions are met' do
      it 'copies timelogs from one issue to another', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with(
          "Copying timelogs from issue #{from_issue.id} to issue #{to_issue.id}")

        expect do
          described_class.new.perform(from_issue.id, to_issue.id)
        end.to change { Timelog.count }.by(1)

        new_timelog = Timelog.last

        expect(new_timelog.issue_id).to eq(to_issue.id)
        expect(new_timelog.project_id).to eq(to_issue.project_id)
      end
    end

    context 'when from_issue does not exist' do
      it 'does not copy timelogs' do
        expect do
          described_class.new.perform(nil, to_issue.id)
        end.not_to change { Timelog.count }
      end
    end

    context 'when to_issue does not exist' do
      it 'does not copy timelogs' do
        expect do
          described_class.new.perform(from_issue.id, nil)
        end.not_to change { Timelog.count }
      end
    end

    context 'when from_issue has no timelogs' do
      let(:from_issue_without_timelog) { create(:issue) }

      it 'does not copy timelogs' do
        expect do
          described_class.new.perform(from_issue_without_timelog.id, to_issue.id)
        end.not_to change { Timelog.count }
      end
    end
  end
end
