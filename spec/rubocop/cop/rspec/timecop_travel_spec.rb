# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/rspec/timecop_travel'

RSpec.describe RuboCop::Cop::RSpec::TimecopTravel do
  subject(:cop) { described_class.new }

  context 'when calling Timecop.travel' do
    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(<<~CODE)
        Timecop.travel(1.day.ago) { create(:issue) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `Timecop.travel`, use `travel_to` instead. [...]
      CODE

      expect_correction(<<~CODE)
        travel_to(1.day.ago) { create(:issue) }
      CODE
    end
  end

  context 'when calling a different method on Timecop' do
    it 'does not register an offense' do
      expect_no_offenses(<<~CODE)
        Timecop.freeze { create(:issue) }
      CODE
    end
  end
end
