# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/change_timzone'

describe RuboCop::Cop::Gitlab::ChangeTimezone do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'Time.zone=' do
    it 'registers an offense with no 2nd argument' do
      expect_offense(<<~PATTERN.strip_indent)
        Time.zone = 'Awkland'
        ^^^^^^^^^^^^^^^^^^^^^ Do not change timezone in the runtime (application or rspec), it could result in silently modifying other behavior.
      PATTERN
    end
  end
end
