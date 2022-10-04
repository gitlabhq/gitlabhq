# frozen_string_literal: true

RSpec.shared_context 'with rpm package data' do
  def xml_update_params
    Gitlab::Json.parse(fixture_file('packages/rpm/payload.json')).with_indifferent_access
  end
end
