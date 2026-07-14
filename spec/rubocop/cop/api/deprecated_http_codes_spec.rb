# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/deprecated_http_codes'

RSpec.describe RuboCop::Cop::API::DeprecatedHttpCodes, :config, feature_category: :api do
  context 'when desc block uses http_codes' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        desc 'Delete a thing' do
          http_codes [[204, 'Thing was deleted'], [403, 'Forbidden']]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `http_codes` in API desc blocks. Use `success`/ `failure` instead. https://docs.gitlab.com/development/api_styleguide/#defining-endpoint-success.
          tags %w[things]
        end
      RUBY
    end

    context 'when success and failure are also declared' do
      it 'still registers an offense' do
        expect_offense(<<~RUBY)
          desc 'Delete a thing' do
            http_codes [[204, 'Thing was deleted'], [403, 'Forbidden']]
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `http_codes` in API desc blocks. Use `success`/ `failure` instead. https://docs.gitlab.com/development/api_styleguide/#defining-endpoint-success.
            success code: 204, message: 'Thing was deleted'
            failure [{ code: 403, message: 'Forbidden' }]
            tags %w[things]
          end
        RUBY
      end
    end

    context 'when success and failure are declared before http_codes' do
      it 'still registers an offense' do
        expect_offense(<<~RUBY)
          desc 'Delete a thing' do
            success code: 204, message: 'Thing was deleted'
            failure [{ code: 403, message: 'Forbidden' }]
            http_codes [[204, 'Thing was deleted'], [403, 'Forbidden']]
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `http_codes` in API desc blocks. Use `success`/ `failure` instead. https://docs.gitlab.com/development/api_styleguide/#defining-endpoint-success.
            tags %w[things]
          end
        RUBY
      end
    end
  end

  context 'when desc block uses success and failure' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc 'Get a list of things' do
          success Entities::Thing
          failure [{ code: 404, message: 'Not found' }]
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
