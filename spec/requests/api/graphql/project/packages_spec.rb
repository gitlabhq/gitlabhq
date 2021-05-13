# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a project' do
  include GraphqlHelpers

  let_it_be(:resource) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project1) { resource }
  let_it_be(:project2) { resource }

  let(:resource_type) { :project }

  it_behaves_like 'group and project packages query'
end
