# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Every model", feature_category: :shared do
  describe 'disallows STI', :eager_load do
    let(:models) { ApplicationRecord.descendants.reject(&:abstract_class?) }

    it 'does not allow STI', :aggregate_failures do
      models.each do |model|
        next if model == model.base_class
        next if model.allow_legacy_sti_class

        expect(model).not_to have_attribute(model.inheritance_column),
          "Do not use Single Table Inheritance (`#{model.name}` inherits `#{model.base_class.name}`). " \
          "See https://docs.gitlab.com/ee/development/database/single_table_inheritance.html"
      end
    end
  end
end
