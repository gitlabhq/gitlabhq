# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/description_success_response'

RSpec.describe RuboCop::Cop::API::DescriptionSuccessResponse, :config, feature_category: :api do
  context 'when desc block includes success' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc 'Get a list of things' do
          detail 'This endpoint was introduced in 18.2'
          success Entities::Thing
          tags %w[things]
        end
      RUBY
    end

    context 'when desc block only includes success' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          desc 'Get a list of things' do
            success Entities::Thing
          end
        RUBY
      end
    end
  end

  context 'when desc block does not have a success' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        desc 'Get a list of things' do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define a success response. https://docs.gitlab.com/development/api_styleguide/#defining-endpoint-success.
          tags %w[things]
        end
      RUBY
    end
  end
end
