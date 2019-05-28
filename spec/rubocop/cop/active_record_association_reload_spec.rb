# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require_relative '../../../rubocop/cop/active_record_association_reload'

describe RuboCop::Cop::ActiveRecordAssociationReload do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when using ActiveRecord::Base' do
    it 'registers an offense on reload usage' do
      expect_offense(<<~PATTERN.strip_indent)
        users = User.all
        users.reload
              ^^^^^^ Use reset instead of reload. For more details check the https://gitlab.com/gitlab-org/gitlab-ce/issues/60218.
        PATTERN
    end

    it 'does not register an offense on reset usage' do
      expect_no_offenses(<<~PATTERN.strip_indent)
        users = User.all
        users.reset
      PATTERN
    end
  end

  context 'when using ActiveRecord::Relation' do
    it 'registers an offense on reload usage' do
      expect_offense(<<~PATTERN.strip_indent)
        user = User.new
        user.reload
             ^^^^^^ Use reset instead of reload. For more details check the https://gitlab.com/gitlab-org/gitlab-ce/issues/60218.
      PATTERN
    end

    it 'does not register an offense on reset usage' do
      expect_no_offenses(<<~PATTERN.strip_indent)
        user = User.new
        user.reset
      PATTERN
    end
  end

  context 'when using on self' do
    it 'registers an offense on reload usage' do
      expect_offense(<<~PATTERN.strip_indent)
        reload
        ^^^^^^ Use reset instead of reload. For more details check the https://gitlab.com/gitlab-org/gitlab-ce/issues/60218.
      PATTERN
    end

    it 'does not register an offense on reset usage' do
      expect_no_offenses(<<~PATTERN.strip_indent)
        reset
      PATTERN
    end
  end
end
