# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::ProjectsController, feature_category: :groups_and_projects do
  context 'token authentication' do
    it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: false do
      let(:url) { dashboard_projects_url(:atom) }
    end
  end
end
