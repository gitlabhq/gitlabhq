# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require './keeps/helpers/rubocop_fixer/config_helper'

RSpec.describe Keeps::Helpers::RubocopFixer::ConfigHelper, feature_category: :tooling do
  using RSpec::Parameterized::TableSyntax

  let(:config_helper) { described_class.new }

  describe '#can_autocorrect?' do
    where(:rule_name, :expected_result, :description) do
      'Style/ModuleFunction'       | false | 'autocorrect is not supported in default rubocop config'
      'Style/MutableConstant'      | false | 'safe autocorrect is not supported in default rubocop config'
      'Rails/Pluck'                | false | 'autocorrect is not supported in gitlab rubocop config'
      'Gitlab/Rails/AttrEncrypted' | false | 'safe autocorrect is not supported in gitlab rubocop config'
      'Layout/ArrayAlignment'      | true  | 'safe autocorrect is supported in default and gitlab rubocop config'
    end

    with_them do
      subject(:can_autocorrect?) { config_helper.can_autocorrect?(rule_name) }

      it { is_expected.to be(expected_result) }
    end
  end
end
