# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::GroupGroupLinkSerializer do
  include_context 'group_group_link'

  subject(:json) { described_class.new.represent(shared_group.shared_with_group_links).to_json }

  it 'matches json schema' do
    expect(json).to match_schema('group_link/group_group_links')
  end
end
