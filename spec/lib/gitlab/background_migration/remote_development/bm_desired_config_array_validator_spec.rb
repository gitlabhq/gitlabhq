# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoteDevelopment::BmDesiredConfigArrayValidator, feature_category: :workspaces do
  include_context "with remote development shared fixtures"
  let(:model) do
    Class.new do
      # @return [String]
      def self.name
        "DesiredConfigArrayValidatorTest"
      end

      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :desired_config_array
      alias_method :desired_config_before_type_cast, :desired_config_array

      validates :desired_config_array, 'remote_development/desired_config_array': true
    end.new
  end

  let(:desired_config_array_with_jumbled_items) do
    items = create_desired_config_array
    items[0], items[-1] = items[-1], items[0]
    items[6], items[7] = items[7], items[6]
    items
  end

  let(:desired_config_array_with_unexpected_items) do
    items = create_desired_config_array
    items << { kind: "UnexpectedKind", metadata: { name: "unexpected-item" } }
    items
  end

  let(:desired_config_array_with_missing_items) { create_desired_config_array.tap { |items| items.delete_at(3) } }

  using RSpec::Parameterized::TableSyntax

  where(:desired_config_array, :validity, :errors) do
    # rubocop:disable Layout/LineLength -- The RSpec table syntax often requires long lines for errors
    # @formatter:off - Turn off RubyMine autoformatting
    create_desired_config_array                      | true  | {}
    ref(:desired_config_array_with_missing_items)    | true  | {}
    ref(:desired_config_array_with_unexpected_items) | false | { desired_config_array: ["item UnexpectedKind/unexpected-item at index 12 is unexpected"] }
    ref(:desired_config_array_with_jumbled_items)    | false | { desired_config_array: ["item Secret/workspace-991-990-fedcba-file at index 0 must be at 11", "item ConfigMap/workspace-991-990-fedcba-scripts-configmap at index 6 must be at 7", "item NetworkPolicy/workspace-991-990-fedcba at index 7 must be at 6", "item ConfigMap/workspace-991-990-fedcba-workspace-inventory at index 11 must be at 0"] }
    nil                                              | false | { desired_config_array: ['must be an array'] }
    {}                                               | false | { desired_config_array: ['must be an array'] }
    []                                               | false | { desired_config_array: ['must not be empty'] }
    # @formatter:on
    # rubocop:enable Layout/LineLength
  end

  with_them do
    before do
      model.desired_config_array = desired_config_array
      model.validate
    end

    it { expect(model.valid?).to eq(validity) }
    it { expect(model.errors.messages).to eq(errors) }
  end
end
