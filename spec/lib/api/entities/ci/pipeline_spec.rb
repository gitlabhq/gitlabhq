# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::Pipeline do
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }
  let_it_be(:job) { create(:ci_build, name: "rspec", coverage: 30.212, pipeline: pipeline) }

  let(:entity) { described_class.new(pipeline) }

  subject { entity.as_json }

  it 'returns the coverage as a string' do
    expect(subject[:coverage]).to eq '30.21'
  end
end
