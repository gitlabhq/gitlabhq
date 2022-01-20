# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::Pipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline, user: user) }
  let_it_be(:job) { create(:ci_build, name: "rspec", coverage: 30.212, pipeline: pipeline) }

  let(:entity) { described_class.new(pipeline) }

  subject { entity.as_json }

  exposed_fields = %i[before_sha tag yaml_errors created_at updated_at started_at finished_at committed_at duration queued_duration]

  exposed_fields.each do |field|
    it "exposes pipeline #{field}" do
      expect(subject[field]).to eq(pipeline.public_send(field))
    end
  end

  it 'exposes pipeline user basic information' do
    expect(subject[:user].keys).to include(:avatar_url, :web_url)
  end

  it 'exposes pipeline detailed status' do
    expect(subject[:detailed_status].keys).to include(:icon, :favicon)
  end

  it 'exposes pipeline coverage as a string' do
    expect(subject[:coverage]).to eq '30.21'
  end
end
