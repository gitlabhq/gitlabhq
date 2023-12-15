# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every model', feature_category: :shared do
  describe 'disallows STI', :eager_load do
    include_examples 'Model disables STI' do
      let(:models) { ApplicationRecord.descendants.reject(&:abstract_class?) }
    end
  end
end
