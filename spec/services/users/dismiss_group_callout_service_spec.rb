# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DismissGroupCalloutService, feature_category: :user_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:params) { { feature_name: feature_name, group_id: group.id } }
    let(:feature_name) { Users::GroupCallout.feature_names.each_key.first }

    subject(:execute) do
      described_class.new(
        container: nil, current_user: user, params: params
      ).execute
    end

    it_behaves_like 'dismissing user callout', Users::GroupCallout

    it 'sets the group_id' do
      expect(execute.group_id).to eq(group.id)
    end
  end
end
