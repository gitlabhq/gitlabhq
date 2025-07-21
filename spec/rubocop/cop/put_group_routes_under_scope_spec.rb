# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/put_group_routes_under_scope'

RSpec.describe RuboCop::Cop::PutGroupRoutesUnderScope do
  %w[resource resources get post put patch delete].each do |route_method|
    it "registers an offense when route is outside scope for `#{route_method}`" do
      offense = "#{route_method} :notes"
      marker = '^' * offense.size

      expect_offense(<<~RUBY)
        scope(path: 'groups/*group_id/-', module: :groups) do
          resource :issues
        end

        #{offense}
        #{marker} Put new group routes under /-/ scope
      RUBY
    end
  end

  it 'does not register an offense when resource inside the scope' do
    expect_no_offenses(<<~RUBY)
      scope(path: 'groups/*group_id/-', module: :groups) do
        resource :issues
        resource :notes
      end
    RUBY
  end

  it 'does not register an offense when resource is deep inside the scope' do
    expect_no_offenses(<<~RUBY)
      scope(path: 'groups/*group_id/-', module: :groups) do
        resource :issues
        resource :projects do
          resource :issues do
            resource :notes
          end
        end
      end
    RUBY
  end

  it 'does not register an offense for the root route' do
    expect_no_offenses(<<~RUBY)
      get '/'
    RUBY
  end

  it 'does not register an offense for the root route within scope' do
    expect_no_offenses(<<~RUBY)
      scope(path: 'groups/*group_id/-', module: :groups) do
        get '/'
      end
    RUBY
  end
end
