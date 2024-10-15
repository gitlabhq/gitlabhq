# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectIdForCiPipelineChatData, migration: :gitlab_ci, feature_category: :continuous_integration do
  let!(:pipeline_101) do
    table(:p_ci_pipelines, primary_key: :id).create!(id: 1, partition_id: 101, project_id: 888)
  end

  let!(:pipeline_102) do
    table(:p_ci_pipelines, primary_key: :id).create!(id: 2, partition_id: 102, project_id: 999)
  end

  let!(:pipeline_chat_data1) do
    table(:ci_pipeline_chat_data).create!(id: 1, pipeline_id: pipeline_101.id, partition_id: pipeline_101.partition_id,
      chat_name_id: 66, response_url: "https://response.com")
  end

  let!(:pipeline_chat_data2) do
    table(:ci_pipeline_chat_data).create!(id: 2, pipeline_id: pipeline_102.id, partition_id: pipeline_102.partition_id,
      chat_name_id: 88, response_url: "https://response.com")
  end

  describe '#up' do
    it 'sets the project_id', :aggregate_failures do
      expect { migrate! }
        .to change { pipeline_chat_data1.reload.project_id }.from(nil).to(pipeline_101.project_id)
        .and change { pipeline_chat_data2.reload.project_id }.from(nil).to(pipeline_102.project_id)
    end
  end
end
