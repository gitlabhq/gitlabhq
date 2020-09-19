# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupGroupLinkEntity do
  include_context 'group_group_link'

  subject(:json) { described_class.new(group_group_link).to_json }

  it 'matches json schema' do
    expect(json).to match_schema('entities/group_group_link')
  end
end
