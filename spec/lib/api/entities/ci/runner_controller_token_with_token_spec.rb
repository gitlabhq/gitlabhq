# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::RunnerControllerTokenWithToken, feature_category: :continuous_integration do
  let_it_be(:token) { create(:ci_runner_controller_token) }

  subject(:as_json) { described_class.new(token).as_json }

  it 'includes basic fields and token' do
    expect(as_json).to eq({
      id: token.id,
      runner_controller_id: token.runner_controller_id,
      description: token.description,
      created_at: token.created_at,
      updated_at: token.updated_at,
      token: token.token
    })
  end
end
