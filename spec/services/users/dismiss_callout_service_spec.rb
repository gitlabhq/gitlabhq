# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DismissCalloutService, feature_category: :user_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:params) { { feature_name: feature_name } }
    let(:feature_name) { Users::Callout.feature_names.each_key.first }

    subject(:execute) do
      described_class.new(
        container: nil, current_user: user, params: params
      ).execute
    end

    it_behaves_like 'dismissing user callout', Users::Callout
  end
end
