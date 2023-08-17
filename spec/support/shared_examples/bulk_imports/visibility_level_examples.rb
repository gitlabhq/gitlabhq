# frozen_string_literal: true

RSpec.shared_examples 'visibility level settings' do |skip_nil_destination_tests|
  using RSpec::Parameterized::TableSyntax

  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:internal_group) { create(:group, :internal) }
  let_it_be(:private_group) { create(:group, :private) }
  let(:data) { { 'visibility' => visibility_level } }

  subject(:transformed_data) { described_class.new.transform(context, data) }

  where(
    :visibility_level,
    :destination_group,
    :restricted_level,
    :expected
  ) do
    'public'      | ref(:public_group)    | nil   | 20
    'public'      | ref(:public_group)    | 20    | 10
    'public'      | ref(:public_group)    | 10    | 20
    'public'      | ref(:public_group)    | 0     | 20
    'public'      | ref(:internal_group)  | nil   | 10
    'public'      | ref(:internal_group)  | 20    | 10
    'public'      | ref(:internal_group)  | 10    | 0
    'public'      | ref(:internal_group)  | 0     | 10
    'public'      | ref(:private_group)   | nil   | 0
    'public'      | ref(:private_group)   | 20    | 0
    'public'      | ref(:private_group)   | 10    | 0
    'public'      | ref(:private_group)   | 0     | 0
    'public'      | nil                   | nil   | 20
    'public'      | nil                   | 20    | 10
    'public'      | nil                   | 10    | 20
    'public'      | nil                   | 0     | 20
    'internal'    | ref(:public_group)    | nil   | 10
    'internal'    | ref(:public_group)    | 20    | 10
    'internal'    | ref(:public_group)    | 10    | 0
    'internal'    | ref(:public_group)    | 0     | 10
    'internal'    | ref(:internal_group)  | nil   | 10
    'internal'    | ref(:internal_group)  | 20    | 10
    'internal'    | ref(:internal_group)  | 10    | 0
    'internal'    | ref(:internal_group)  | 0     | 10
    'internal'    | ref(:private_group)   | nil   | 0
    'internal'    | ref(:private_group)   | 20    | 0
    'internal'    | ref(:private_group)   | 10    | 0
    'internal'    | ref(:private_group)   | 0     | 0
    'internal'    | nil                   | nil   | 10
    'internal'    | nil                   | 20    | 10
    'internal'    | nil                   | 10    | 0
    'internal'    | nil                   | 0     | 10
    'private'     | ref(:public_group)    | nil   | 0
    'private'     | ref(:public_group)    | 20    | 0
    'private'     | ref(:public_group)    | 10    | 0
    'private'     | ref(:public_group)    | 0     | 0
    'private'     | ref(:internal_group)  | nil   | 0
    'private'     | ref(:internal_group)  | 20    | 0
    'private'     | ref(:internal_group)  | 10    | 0
    'private'     | ref(:internal_group)  | 0     | 0
    'private'     | ref(:private_group)   | nil   | 0
    'private'     | ref(:private_group)   | 20    | 0
    'private'     | ref(:private_group)   | 10    | 0
    'private'     | ref(:private_group)   | 0     | 0
    'private'     | nil                   | nil   | 0
    'private'     | nil                   | 20    | 0
    'private'     | nil                   | 10    | 0
    'private'     | nil                   | 0     | 0
  end

  with_them do
    before do
      stub_application_setting(restricted_visibility_levels: [restricted_level])
    end

    it 'has the correct visibility level' do
      next if destination_group.nil? && skip_nil_destination_tests

      expect(transformed_data[:visibility_level]).to eq(expected)
    end
  end
end
