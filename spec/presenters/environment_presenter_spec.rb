# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentPresenter, feature_category: :continuous_delivery do
  subject(:presenter) { described_class.new(environment) }

  let_it_be(:environment) { build(:environment) }

  describe '#deployments_display_count' do
    subject { presenter.deployments_display_count }

    before do
      stub_const("#{described_class}::MAX_DEPLOYMENTS_COUNT", 5)
      allow(environment).to receive_message_chain(:all_deployments,
        :limit).with(described_class::MAX_DEPLOYMENTS_COUNT).and_return(deployments_list)
    end

    context 'with less than the maximum deployments' do
      let_it_be(:deployments_list) { build_stubbed_list(:deployment, 3) }

      it 'returns the actual deployments count' do
        is_expected.to eq('3')
      end
    end

    context 'with more than the maximum deployments' do
      let_it_be(:deployments_list) { build_stubbed_list(:deployment, 6) }

      it 'returns MAX_DISPLAY_COUNT value' do
        is_expected.to eq(described_class::MAX_DISPLAY_COUNT)
      end
    end
  end
end
