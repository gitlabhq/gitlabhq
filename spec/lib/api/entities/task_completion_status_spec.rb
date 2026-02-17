# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::TaskCompletionStatus, feature_category: :team_planning do
  let(:status) { { count: 4, completed_count: 2 } }

  subject(:representation) { described_class.new(status).as_json }

  it 'exposes the task counts' do
    expect(representation).to include(count: 4, completed_count: 2)
  end
end
