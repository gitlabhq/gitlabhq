# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::CreateForJobService, feature_category: :continuous_delivery do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new }

  it_behaves_like 'create deployment for job' do
    let(:factory_type) { :ci_build }
  end

  it_behaves_like 'create deployment for job' do
    let(:factory_type) { :ci_bridge }
  end
end
