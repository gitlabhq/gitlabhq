# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/group_public_or_visible_to_user'

RSpec.describe RuboCop::Cop::GroupPublicOrVisibleToUser, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of Group.public_or_visible_to_user with a constant receiver' do
    inspect_source('Group.public_or_visible_to_user')

    expect(cop.offenses.size).to eq(1)
  end

  it 'does not flat the use of public_or_visible_to_user with a constant that is not Group' do
    inspect_source('Project.public_or_visible_to_user')

    expect(cop.offenses.size).to eq(0)
  end

  it 'does not flag the use of Group.public_or_visible_to_user with a send receiver' do
    inspect_source('foo.public_or_visible_to_user')

    expect(cop.offenses.size).to eq(0)
  end
end
