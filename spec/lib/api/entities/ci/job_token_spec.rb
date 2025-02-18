# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobToken, feature_category: :continuous_integration do
  let_it_be(:job) { create(:ci_build) }

  subject(:job_token_entity) { described_class.new(job).as_json }

  it "exposes job" do
    expect(job_token_entity).to include(:job)
  end
end
