# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerController, feature_category: :continuous_integration do
  let_it_be(:controller) { create(:ci_runner_controller) }

  subject { controller.as_json }

  it 'includes basic fields' do
    is_expected.to include(
      'id' => controller.id,
      'description' => controller.description,
      'created_at' => controller.created_at.as_json,
      'updated_at' => controller.updated_at.as_json
    )
  end
end
