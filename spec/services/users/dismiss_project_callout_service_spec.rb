# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DismissProjectCalloutService, feature_category: :user_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let(:params) { { feature_name: feature_name, project_id: project.id } }
    let(:feature_name) { Users::ProjectCallout.feature_names.each_key.first }

    subject(:execute) do
      described_class.new(
        container: nil, current_user: user, params: params
      ).execute
    end

    it_behaves_like 'dismissing user callout', Users::ProjectCallout

    it 'sets the project_id' do
      expect(execute.project_id).to eq(project.id)
    end
  end
end
