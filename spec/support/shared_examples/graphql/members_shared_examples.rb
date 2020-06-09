# frozen_string_literal: true

RSpec.shared_examples 'a working membership object query' do |model_option|
  let_it_be(:member_source) { member.source }
  let_it_be(:member_source_type) { member_source.class.to_s.downcase }

  it 'contains edge to expected project' do
    expect(
      graphql_data.dig('user', "#{member_source_type}Memberships", 'nodes', 0, member_source_type, 'id')
    ).to eq(member.send(member_source_type).to_global_id.to_s)
  end

  it 'contains correct access level' do
    expect(
      graphql_data.dig('user', "#{member_source_type}Memberships", 'nodes', 0, 'accessLevel', 'integerValue')
    ).to eq(30)

    expect(
      graphql_data.dig('user', "#{member_source_type}Memberships", 'nodes', 0, 'accessLevel', 'stringValue')
    ).to eq('DEVELOPER')
  end
end
