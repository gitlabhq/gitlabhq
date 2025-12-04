# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Permission, feature_category: :permissions do
  let(:definition) do
    {
      name: 'test_permission',
      description: 'Test permission description',
      feature_category: 'team_planning'
    }
  end

  subject(:permission) { described_class.new(definition,  'config/authz/permissions/permission/test.yml') }

  it_behaves_like 'loadable yaml permission or permission group' do
    let(:definition_name) { :create_issue }
  end
end
