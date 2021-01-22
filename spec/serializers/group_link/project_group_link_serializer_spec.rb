# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::ProjectGroupLinkSerializer do
  let_it_be(:project_group_links) { create_list(:project_group_link, 1) }

  subject(:json) { described_class.new.represent(project_group_links).to_json }

  it 'matches json schema' do
    expect(json).to match_schema('group_link/project_group_links')
  end
end
