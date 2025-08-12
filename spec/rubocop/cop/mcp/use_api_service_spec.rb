# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/mcp/use_api_service'

RSpec.describe RuboCop::Cop::Mcp::UseApiService, feature_category: :mcp_server do
  let(:msg) do
    'Inherit from ApiService when API endpoints exist for this functionality. ' \
      'ApiService handles authentication/authorization automatically via API requests. ' \
      'Direct BaseService inheritance requires implementing manual Ability checks.'
  end

  it 'flags classes inheriting from BaseService' do
    expect_offense(<<~RUBY, msg: msg)
      module Mcp
        module Tools
          class CustomTool < BaseService
                             ^^^^^^^^^^^ %{msg}
          end
        end
      end
    RUBY
  end

  it 'flags classes inheriting from ::Mcp::Tools::BaseService' do
    expect_offense(<<~RUBY, msg: msg)
      module Mcp
        module Tools
          class CustomTool < ::Mcp::Tools::BaseService
                             ^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        end
      end
    RUBY
  end

  it 'does not flag classes inheriting from ApiService' do
    expect_no_offenses(<<~RUBY)
      module Mcp
        module Tools
          class CustomTool < ApiService
          end
        end
      end
    RUBY
  end

  it 'does not flag classes inheriting from ::Mcp::Tools::ApiService' do
    expect_no_offenses(<<~RUBY)
      module Mcp
        module Tools
          class CustomTool < ::Mcp::Tools::ApiService
          end
        end
      end
    RUBY
  end

  it 'does not flag ApiService class inheriting from BaseService' do
    expect_no_offenses(<<~RUBY)
      module Mcp
        module Tools
          class ApiService < BaseService
          end
        end
      end
    RUBY
  end

  it 'does not flag ApiService class inheriting from ::Mcp::Tools::BaseService' do
    expect_no_offenses(<<~RUBY)
      module Mcp
        module Tools
          class ApiService < ::Mcp::Tools::BaseService
          end
        end
      end
    RUBY
  end

  it 'flags classes outside of Mcp::Tools inheriting from BaseService' do
    expect_offense(<<~RUBY, msg: msg)
      class SomeOtherClass < BaseService
                             ^^^^^^^^^^^ %{msg}
      end
    RUBY
  end

  it 'does not flag classes with different parent class names' do
    expect_no_offenses(<<~RUBY)
      module Mcp
        module Tools
          class CustomTool < ApplicationService
          end
        end
      end
    RUBY
  end

  it 'flags classes inheriting from BaseService with class body' do
    expect_offense(<<~RUBY, msg: msg)
      module Mcp
        module Tools
          class CustomTool < BaseService
                             ^^^^^^^^^^^ %{msg}
            def perform
              puts "doing work"
            end
          end
        end
      end
    RUBY
  end

  it 'does not auto-correct offenses' do
    expect_offense(<<~RUBY, msg: msg)
      module Mcp
        module Tools
          class CustomTool < BaseService
                             ^^^^^^^^^^^ %{msg}
          end
        end
      end
    RUBY

    expect_no_corrections
  end
end
