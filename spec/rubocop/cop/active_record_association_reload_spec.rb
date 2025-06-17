# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/active_record_association_reload'

RSpec.describe RuboCop::Cop::ActiveRecordAssociationReload do
  context 'when using ActiveRecord::Base' do
    it 'registers an offense on reload usage' do
      expect_offense(<<~RUBY)
        users = User.all
        users.reload
              ^^^^^^ Use reset instead of reload. For more details check the https://gitlab.com/gitlab-org/gitlab-foss/issues/60218.
      RUBY
    end

    it 'does not register an offense on reset usage' do
      expect_no_offenses(<<~RUBY)
        users = User.all
        users.reset
      RUBY
    end
  end

  context 'when using ActiveRecord::Relation' do
    it 'registers an offense on reload usage' do
      expect_offense(<<~RUBY)
        user = User.new
        user.reload
             ^^^^^^ Use reset instead of reload. For more details check the https://gitlab.com/gitlab-org/gitlab-foss/issues/60218.
      RUBY
    end

    it 'does not register an offense on reset usage' do
      expect_no_offenses(<<~RUBY)
        user = User.new
        user.reset
      RUBY
    end
  end

  context 'when using on self' do
    it 'registers an offense on reload usage' do
      expect_offense(<<~RUBY)
        reload
        ^^^^^^ Use reset instead of reload. For more details check the https://gitlab.com/gitlab-org/gitlab-foss/issues/60218.
      RUBY
    end

    it 'does not register an offense on reset usage' do
      expect_no_offenses(<<~RUBY)
        reset
      RUBY
    end
  end
end
