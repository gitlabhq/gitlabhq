# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../rubocop/cop/group_public_or_visible_to_user'

RSpec.describe RuboCop::Cop::GroupPublicOrVisibleToUser do
  let(:msg) do
    "`Group.public_or_visible_to_user` should be used with extreme care. " \
    "Please ensure that you are not using it on its own and that the amount of rows being filtered is reasonable."
  end

  subject(:cop) { described_class.new }

  it 'flags the use of Group.public_or_visible_to_user with a constant receiver' do
    expect_offense(<<~CODE)
      Group.public_or_visible_to_user
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    CODE
  end

  it 'does not flag the use of public_or_visible_to_user with a constant that is not Group' do
    expect_no_offenses('Project.public_or_visible_to_user')
  end

  it 'does not flag the use of Group.public_or_visible_to_user with a send receiver' do
    expect_no_offenses('foo.public_or_visible_to_user')
  end
end
