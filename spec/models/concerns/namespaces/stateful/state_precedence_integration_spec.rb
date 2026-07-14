# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::StatePrecedence, feature_category: :groups_and_projects do
  describe 'STATE_PRECEDENCE consistency with canonical enum' do
    it 'has keys and values that match Namespace.states for the propagation-relevant states',
      :aggregate_failures do
      canonical_states = Namespace.states

      described_class::STATE_PRECEDENCE.each do |state_name, precedence_value|
        expect(canonical_states).to include(state_name.to_s),
          "STATE_PRECEDENCE key :#{state_name} is not present in Namespace.states. " \
            "If the canonical enum was renamed, update STATE_PRECEDENCE to match."

        expect(canonical_states[state_name.to_s]).to eq(precedence_value),
          "STATE_PRECEDENCE[:#{state_name}] is #{precedence_value} but Namespace.states" \
            "['#{state_name}'] is #{canonical_states[state_name.to_s]}. " \
            "Update STATE_PRECEDENCE to match the canonical enum."
      end
    end

    it 'defines a precedence for every propagated state', :aggregate_failures do
      Namespaces::Stateful::PROPAGATED_STATES.each do |state_name|
        expect(described_class::STATE_PRECEDENCE).to include(state_name),
          "PROPAGATED_STATES includes :#{state_name} but STATE_PRECEDENCE has no entry for it. " \
            "Every propagated state must have a precedence so propagation ordering is defined."
      end
    end
  end
end
