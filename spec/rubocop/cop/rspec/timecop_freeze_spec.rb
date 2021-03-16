# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/rspec/timecop_freeze'

RSpec.describe RuboCop::Cop::RSpec::TimecopFreeze do
  subject(:cop) { described_class.new }

  context 'when calling Timecop.freeze' do
    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(<<~CODE)
        Timecop.freeze(Time.current) { example.run }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `Timecop.freeze`, use `freeze_time` instead. [...]
      CODE

      expect_correction(<<~CODE)
        freeze_time(Time.current) { example.run }
      CODE
    end
  end

  context 'when calling a different method on Timecop' do
    it 'does not register an offense' do
      expect_no_offenses(<<~CODE)
        Timecop.travel(Time.current)
      CODE
    end
  end
end
