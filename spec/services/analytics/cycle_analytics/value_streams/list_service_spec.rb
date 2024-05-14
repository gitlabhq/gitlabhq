# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ValueStreams::ListService, feature_category: :value_stream_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:service) { described_class.new(parent: project.project_namespace, current_user: user) }

  subject(:service_response) { service.execute }

  it 'returns the default value stream' do
    project.add_developer(user)
    expect(service_response).to be_success
    expect(service_response.payload[:value_streams]).to match([have_attributes(name: 'default')])
  end

  context 'when the user is not part of the project' do
    it 'fails' do
      expect(service_response).to be_error
    end
  end
end
