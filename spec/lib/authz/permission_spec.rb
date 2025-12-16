# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Permission, feature_category: :permissions do
  it_behaves_like 'loadable from yaml' do
    let(:definition_name) { :create_issue }
  end

  it_behaves_like 'yaml backed permission'
end
