# frozen_string_literal: true

# Asserts Namespaces::GroupsFinder returns the same groups as GroupsFinder for a given
# param set, so call sites can be migrated one at a time without behaviour drift.
#
# Requires `current_user` and `params` to be defined.
RSpec.shared_examples 'a finder returning the same groups as GroupsFinder' do
  it 'returns the same groups as GroupsFinder' do
    expected = GroupsFinder.new(current_user, params).execute

    expect(described_class.new(current_user, params).execute).to match_array(expected)
  end
end
