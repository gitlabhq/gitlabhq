# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'searching groups for the admin area', :with_license, feature_category: :groups_and_projects do
  it_behaves_like 'groups query' do
    let(:field_name) { :adminGroups }
    let(:fields) do
      "nodes {
        ... on Group {
          #{group_fields}
        }
      }
      count"
    end
  end
end
