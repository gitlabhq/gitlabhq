# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineScheduleEntity, feature_category: :continuous_integration do
  include Gitlab::Routing

  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:pipeline_schedule) { build_stubbed(:ci_pipeline_schedule, :nightly, project: project) }

  let(:request) { instance_double(ActionDispatch::Request) }
  let(:entity) { described_class.new(pipeline_schedule, request: request) }

  subject(:data) { entity.as_json }

  it { is_expected.to include(:id) }
  it { is_expected.to include(:description) }
  it { is_expected.to include(:path) }

  it { expect(data[:id]).to eq(pipeline_schedule.id) }
  it { expect(data[:description]).to eq(pipeline_schedule.description) }
  it { expect(data[:path]).to eq(pipeline_schedules_path(pipeline_schedule.project)) }
end
