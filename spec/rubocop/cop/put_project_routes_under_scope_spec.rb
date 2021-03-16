# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../rubocop/cop/put_project_routes_under_scope'

RSpec.describe RuboCop::Cop::PutProjectRoutesUnderScope do
  subject(:cop) { described_class.new }

  %w[resource resources get post put patch delete].each do |route_method|
    it "registers an offense when route is outside scope for `#{route_method}`" do
      offense = "#{route_method} :notes"
      marker = '^' * offense.size

      expect_offense(<<~PATTERN)
      scope '-' do
        resource :issues
      end

      #{offense}
      #{marker} Put new project routes under /-/ scope
      PATTERN
    end
  end

  it 'does not register an offense when resource inside the scope' do
    expect_no_offenses(<<~PATTERN)
      scope '-' do
        resource :issues
        resource :notes
      end
    PATTERN
  end

  it 'does not register an offense when resource is deep inside the scope' do
    expect_no_offenses(<<~PATTERN)
      scope '-' do
        resource :issues
        resource :projects do
          resource :issues do
            resource :notes
          end
        end
      end
    PATTERN
  end

  it 'does not register an offense for the root route' do
    expect_no_offenses(<<~PATTERN)
      get '/'
    PATTERN
  end

  it 'does not register an offense for the root route within scope' do
    expect_no_offenses(<<~PATTERN)
      scope '-' do
        get '/'
      end
    PATTERN
  end
end
