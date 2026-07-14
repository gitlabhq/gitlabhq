# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/description_failure_response'

RSpec.describe RuboCop::Cop::API::DescriptionFailureResponse, :config, feature_category: :api do
  context 'when desc block includes failure' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc 'Get a list of things' do
          detail 'This endpoint was introduced in 18.2'
          success Entities::Thing
          failure [{ code: 404, message: 'Not found' }]
          tags %w[things]
        end
      RUBY
    end

    context 'when desc block only includes failure' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          desc 'Get a list of things' do
            failure [{ code: 404, message: 'Not found' }]
          end
        RUBY
      end
    end

    context 'when failure is declared without an array' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          desc 'Get a list of things' do
            failure code: 401, message: 'Unauthorized'
          end
        RUBY
      end
    end
  end

  context 'when desc block does not have a failure' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        desc 'Get a list of things' do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define a failure response. https://docs.gitlab.com/development/api_styleguide/#defining-endpoint-failures.
          success Entities::Thing
          tags %w[things]
        end
      RUBY
    end
  end

  context 'when the block is not a desc block' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :id, type: Integer
        end
      RUBY
    end
  end

  context 'when desc has no block' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc 'Get a list of things'
      RUBY
    end
  end
end
