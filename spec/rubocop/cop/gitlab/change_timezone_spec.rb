# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/change_timezone'

RSpec.describe RuboCop::Cop::Gitlab::ChangeTimezone do
  context 'Time.zone=' do
    it 'registers an offense with no 2nd argument' do
      expect_offense(<<~PATTERN)
        Time.zone = 'Awkland'
        ^^^^^^^^^^^^^^^^^^^^^ Do not change timezone in the runtime (application or rspec), it could result [...]
      PATTERN
    end
  end
end
