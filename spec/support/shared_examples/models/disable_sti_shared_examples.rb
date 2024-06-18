# frozen_string_literal: true

# Checks whether STI is disabled in +models+.
#
# Parameter:
# - models: List of model classes
RSpec.shared_examples 'Model disables STI' do
  skip_sti_check = Gitlab::Utils.to_boolean(ENV['SKIP_STI_CHECK'], default: false)

  it 'does not allow STI', :aggregate_failures, unless: skip_sti_check do
    models.each do |model|
      next unless model
      next unless model < ApplicationRecord
      next unless model.name # skip unnamed/anonymous models
      next if model.table_name&.start_with?('_test') # skip test models that define the tables in specs
      next if model == model.base_class
      next if model.allow_legacy_sti_class

      expect(model).not_to have_attribute(model.inheritance_column),
        "Do not use Single Table Inheritance (`#{model.name}` inherits `#{model.base_class.name}`). " \
        "See https://docs.gitlab.com/ee/development/database/single_table_inheritance.html"
    end
  end
end

RSpec.shared_examples 'STI disabled', type: :model do # rubocop:disable RSpec/SharedGroupsMetadata -- Shared example is run within every spec tagged `type: :model`
  include_examples 'Model disables STI' do
    let(:models) { [described_class] }
  end
end
