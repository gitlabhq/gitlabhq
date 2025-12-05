# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/description_summary'

RSpec.describe RuboCop::Cop::API::DescriptionSummary, :config, feature_category: :api do
  let(:msg_missing) do
    'API desc blocks must define a summary string. ' \
      'https://docs.gitlab.com/development/api_styleguide#defining-endpoint-desc'
  end

  let(:msg_too_long) do
    'API desc summary must not exceed 120 characters. ' \
      'https://docs.gitlab.com/development/api_styleguide#defining-endpoint-desc'
  end

  context 'when desc block has no summary' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        desc do
        ^^^^ #{msg_missing}
          detail 'Some detail'
        end
      RUBY
    end
  end

  context 'when desc block summary is not a string' do
    it 'registers an offense for a variable' do
      expect_offense(<<~RUBY)
        desc some_variable do
        ^^^^^^^^^^^^^^^^^^ #{msg_missing}
          detail 'Some detail'
        end
      RUBY
    end

    it 'registers an offense for a method call' do
      expect_offense(<<~RUBY)
        desc some_method(:arg) do
        ^^^^^^^^^^^^^^^^^^^^^^ #{msg_missing}
          detail 'Some detail'
        end
      RUBY
    end

    it 'registers an offense for a constant' do
      expect_offense(<<~RUBY)
        desc SUMMARY do
        ^^^^^^^^^^^^ #{msg_missing}
          detail 'Some detail'
        end
      RUBY
    end
  end

  context 'when desc block summary exceeds 120 characters' do
    it 'registers an offense' do
      long_summary = 'a' * 121

      expect_offense(<<~RUBY)
        desc '#{long_summary}' do
             ^#{'^' * 121}^ #{msg_too_long}
          detail 'Some detail'
        end
      RUBY
    end
  end

  context 'when desc block has a valid summary' do
    it 'does not register an offense for a short summary' do
      expect_no_offenses(<<~RUBY)
        desc 'Get a specific environment' do
          detail 'Some detail'
        end
      RUBY
    end

    it 'does not register an offense for a summary at exactly 120 characters' do
      summary = 'a' * 120

      expect_no_offenses(<<~RUBY)
        desc '#{summary}' do
          detail 'Some detail'
        end
      RUBY
    end

    it 'does not register an offense for an interpolated string' do
      expect_no_offenses(<<~RUBY)
        desc "Get a single \#{eventable_type.to_s.downcase} resource event" do
          detail 'Some detail'
        end
      RUBY
    end

    it 'does not register an offense for non desc blcok' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :id, type: Integer
          optional :name, type: String
        end
      RUBY
    end
  end
end
