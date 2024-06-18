# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::Job, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline, user: user) }
  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:runner_manager) { create(:ci_runner_machine) }
  let_it_be(:job) { create(:ci_build, pipeline: pipeline, runner_manager: runner_manager) }

  let(:entity) { described_class.new(job) }

  subject(:job_entity) { entity.as_json }

  exposed_fields = %i[id status stage name ref tag coverage allow_failure created_at started_at finished_at erased_at
    user artifacts? duration runner runner_manager artifacts_expire_at tag_list]

  exposed_fields.each do |field|
    it "exposes job #{field}" do
      expect(job_entity[field]).to eq(job.public_send(field)) if field != :runner_manager && field != :runner
    end
  end

  it "exposes job runner" do
    expect(job_entity[:runner]).to include(*%i[id name description status paused is_shared runner_type online])
  end

  it "exposes job runner_manager" do
    expect(job_entity[:runner_manager].keys).to include(*%i[id system_id version revision platform architecture
      created_at contacted_at ip_address status])
  end

  it "exposes job pipeline" do
    expect(job_entity[:pipeline].keys).to include(*%i[id iid project_id sha ref status source created_at updated_at
      web_url])
  end
end
