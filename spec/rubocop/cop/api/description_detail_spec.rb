# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/description_detail'

RSpec.describe RuboCop::Cop::API::DescriptionDetail, :config, feature_category: :api do
  context 'when desc block has a valid detail' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc 'Get a list of things' do
          detail 'This endpoint was introduced in 18.2'
          tags %w[things]
        end
      RUBY
    end

    context "when detail uses interpolation in a string" do
      it "does not add an offense" do
        expect_no_offenses(<<~'RUBY')
          desc "Get a list of #{interpolated} things" do
            detail 'This endpoint was introduced in 18.2'
            tags %w[things]
          end
        RUBY
      end
    end

    context "when desc block only contains detail" do
      it "does not add an offense" do
        expect_no_offenses(<<~'RUBY')
          desc "Get a list of #{interpolated} things" do
            detail 'This endpoint was introduced in 18.2'
          end
        RUBY
      end
    end
  end

  context 'when desc block does not have a detail' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        desc 'Get a list of things' do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define a valid detail string. https://docs.gitlab.com/development/api_styleguide#defining-endpoint-details.
          tags %w[things]
        end
      RUBY
    end
  end

  context 'when detail is not a string' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        desc 'Get a list of things' do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define a valid detail string. https://docs.gitlab.com/development/api_styleguide#defining-endpoint-details.
          detail ['Get', 2, 'list of things']
          tags %w[things]
        end

      RUBY
    end
  end
end
