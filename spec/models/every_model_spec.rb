# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every model', feature_category: :database do
  describe 'disallows STI', :eager_load do
    include_examples 'Model disables STI' do
      let(:models) { ApplicationRecord.descendants.reject(&:abstract_class?) }
    end
  end

  describe 'state machine initial state', :eager_load do
    it 'has no conflicts with database column defaults', :aggregate_failures do
      models = ApplicationRecord.descendants.select { |d| d.respond_to?(:state_machines) }

      models.each do |model|
        model.state_machines.each_value do |machine|
          expect { machine.warn_conflicting_initial_state }.not_to output.to_stderr,
            "#{model.name}##{machine.attribute} has a conflicting initial state with the database column default"
        end
      end
    end
  end
end
