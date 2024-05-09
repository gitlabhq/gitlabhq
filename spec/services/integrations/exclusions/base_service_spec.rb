# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Integrations::Exclusions::BaseService, feature_category: :integrations do
  let(:integration_name) { 'beyond_identity' }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { admin_user }
  let_it_be(:project) { create(:project) }
  let(:service) do
    described_class.new(current_user: current_user, integration_name: integration_name, projects: [project])
  end

  subject(:execute) { service.execute }

  it_behaves_like 'exclusions base service'
end
