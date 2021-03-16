# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/change_timzone'

RSpec.describe RuboCop::Cop::Gitlab::ChangeTimezone do
  subject(:cop) { described_class.new }

  context 'Time.zone=' do
    it 'registers an offense with no 2nd argument' do
      expect_offense(<<~PATTERN)
        Time.zone = 'Awkland'
        ^^^^^^^^^^^^^^^^^^^^^ Do not change timezone in the runtime (application or rspec), it could result [...]
      PATTERN
    end
  end
end
