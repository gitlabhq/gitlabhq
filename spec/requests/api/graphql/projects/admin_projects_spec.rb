# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a collection of projects to admin', feature_category: :source_code_management do
  it_behaves_like 'getting a collection of projects' do
    let(:selection) do
      "nodes {
        ... on Project {
          #{project_fields}
        }
      }"
    end

    let(:field) { :admin_projects }
  end
end
