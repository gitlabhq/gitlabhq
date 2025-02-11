# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::BaseService, feature_category: :team_planning do
  describe '.constructor_container_arg' do
    it { expect(described_class.constructor_container_arg("some-value")).to eq({ container: "some-value" }) }
  end

  describe '#available_callbacks' do
    let_it_be(:project) { create(:project) }

    subject(:service) { described_class.new(container: project, current_user: project.owner, params: {}) }

    specify do
      expect(service.available_callbacks).to include(
        ::WorkItems::Callbacks::StartAndDueDate
      )
    end
  end
end
