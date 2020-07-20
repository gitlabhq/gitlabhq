# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../rubocop/cop/put_group_routes_under_scope'

RSpec.describe RuboCop::Cop::PutGroupRoutesUnderScope, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  before do
    allow(cop).to receive(:in_group_routes?).and_return(true)
  end

  it 'registers an offense when route is outside scope' do
    expect_offense(<<~PATTERN)
      scope(path: 'groups/*group_id/-', module: :groups) do
        resource :issues
      end

      resource :notes
      ^^^^^^^^^^^^^^^ Put new group routes under /-/ scope
    PATTERN
  end

  it 'does not register an offense when resource inside the scope' do
    expect_no_offenses(<<~PATTERN)
      scope(path: 'groups/*group_id/-', module: :groups) do
        resource :issues
        resource :notes
      end
    PATTERN
  end

  it 'does not register an offense when resource is deep inside the scope' do
    expect_no_offenses(<<~PATTERN)
      scope(path: 'groups/*group_id/-', module: :groups) do
        resource :issues
        resource :projects do
          resource :issues do
            resource :notes
          end
        end
      end
    PATTERN
  end
end
