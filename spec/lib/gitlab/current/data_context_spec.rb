# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Current::DataContext, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:anchor1) { create(:organization, :isolated) }
  let_it_be(:anchor2) { create(:organization, :isolated) }
  let_it_be(:anchor) { create(:organization) }

  let_it_be(:iso_home) { create(:organization, :isolated) }
  let_it_be(:home) { create(:organization) }

  let_it_be(:iso_user) { create(:user, organization: iso_home) }
  let_it_be(:home_user) { create(:user, organization: home) }

  describe '#type and #context' do
    subject(:data_context) { described_class.new(organization: organization, user: user) }

    where(:case_name, :organization, :user, :expected_type, :expected_context) do
      'no anchor, no user'                 | nil                  | nil                | :nil          | nil
      'no anchor, non-isolated home'       | nil                  | ref(:home_user)    | :user         | ref(:home_user)
      'no anchor, isolated home'           | nil                  | ref(:iso_user) | :organization | ref(:iso_home)
      'non-isolated anchor, no user'       | ref(:anchor)         | nil                | :nil          | nil
      'non-isolated anchor, non-iso home'  | ref(:anchor)         | ref(:home_user)    | :user         | ref(:home_user)
      'non-isolated anchor, iso home'      | ref(:anchor)         | ref(:iso_user) | :organization | ref(:iso_home)
      'isolated anchor, no user'           | ref(:anchor1)     | nil                | :organization | ref(:anchor1)
      'isolated anchor, non-iso home'      | ref(:anchor1)     | ref(:home_user)    | :organization | ref(:anchor1)
      'anchor == home, both isolated'      | ref(:iso_home) | ref(:iso_user) | :organization | ref(:iso_home)
      'anchor != home, both isolated'      | ref(:anchor2) | ref(:iso_user) | :organization | ref(:iso_home)
    end

    with_them do
      it 'resolves the correct type and context' do
        expect(data_context.type).to eq(expected_type)
        expect(data_context.context).to eq(expected_context)
      end
    end
  end
end
