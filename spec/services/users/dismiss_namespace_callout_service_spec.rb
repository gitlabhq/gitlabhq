# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DismissNamespaceCalloutService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:params) { { feature_name: feature_name, namespace_id: user.namespace.id } }
    let(:feature_name) { Users::NamespaceCallout.feature_names.each_key.first }

    subject(:execute) do
      described_class.new(
        container: nil, current_user: user, params: params
      ).execute
    end

    it_behaves_like 'dismissing user callout', Users::NamespaceCallout

    it 'sets the namespace_id' do
      expect(execute.namespace_id).to eq(user.namespace.id)
    end
  end
end
