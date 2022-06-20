# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ProjectStatsRefreshConflictsLogger do
  before do
    Gitlab::ApplicationContext.push(feature_category: 'test', caller_id: 'caller')
  end

  describe '.warn_artifact_deletion_during_stats_refresh' do
    it 'logs a warning about artifacts being deleted while the project is undergoing stats refresh' do
      project_id = 123
      method = 'Foo#action'

      expect(Gitlab::AppLogger).to receive(:warn).with(
        hash_including(
          message: 'Deleted artifacts undergoing refresh',
          method: method,
          project_id: project_id,
          'correlation_id' => an_instance_of(String),
          'meta.feature_category' => 'test',
          'meta.caller_id' => 'caller'
        )
      )

      described_class.warn_artifact_deletion_during_stats_refresh(project_id: project_id, method: method)
    end
  end

  describe '.warn_request_rejected_during_stats_refresh' do
    it 'logs a warning about artifacts being deleted while the project is undergoing stats refresh' do
      project_id = 123

      expect(Gitlab::AppLogger).to receive(:warn).with(
        hash_including(
          message: 'Rejected request due to project undergoing stats refresh',
          project_id: project_id,
          'correlation_id' => an_instance_of(String),
          'meta.feature_category' => 'test',
          'meta.caller_id' => 'caller'
        )
      )

      described_class.warn_request_rejected_during_stats_refresh(project_id)
    end
  end

  describe '.warn_skipped_artifact_deletion_during_stats_refresh' do
    it 'logs a warning about artifacts being excluded from deletion while the project is undergoing stats refresh' do
      project_ids = [12, 34]
      method = 'Foo#action'

      expect(Gitlab::AppLogger).to receive(:warn).with(
        hash_including(
          message: 'Skipped deleting artifacts undergoing refresh',
          method: method,
          project_ids: match_array(project_ids),
          'correlation_id' => an_instance_of(String),
          'meta.feature_category' => 'test',
          'meta.caller_id' => 'caller'
        )
      )

      described_class.warn_skipped_artifact_deletion_during_stats_refresh(project_ids: project_ids, method: method)
    end
  end
end
