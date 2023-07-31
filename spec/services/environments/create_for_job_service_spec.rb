# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::CreateForJobService, feature_category: :continuous_delivery do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:service) { described_class.new }

  it_behaves_like 'create environment for job' do
    let(:factory_type) { :ci_build }
  end

  it_behaves_like 'create environment for job' do
    let(:factory_type) { :ci_bridge }
  end
end
