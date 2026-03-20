# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'StateMachinesMachineConfigurationPatch', feature_category: :database do
  describe '#initial_state=' do
    it 'does not trigger a DB query during class definition' do
      queries = []
      recorder = ->(_name, _started, _finished, _unique_id, payload) { queries << payload[:sql] }

      ActiveSupport::Notifications.subscribed(recorder, "sql.active_record") do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'namespaces'

          state_machine :state, initial: :something_else
        end
      end

      expect(queries).to be_empty
    end
  end

  describe '#warn_conflicting_initial_state' do
    it 'warns of a conflicting default state' do
      model_with_state_machine = Class.new(ActiveRecord::Base) do
        self.table_name = 'namespaces'

        state_machine :state, initial: :something_else
      end

      machine = model_with_state_machine.state_machine

      expect(machine).to receive(:warn).once.with(a_string_matching(/defined a different default for/))
      machine.warn_conflicting_initial_state
    end
  end
end
