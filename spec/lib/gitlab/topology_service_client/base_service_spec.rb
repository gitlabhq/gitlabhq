# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::BaseService, feature_category: :cell do
  subject(:base_service) { described_class.new }

  describe '#initialize' do
    context 'when cell is disabled' do
      it 'raises an error when cell is not enabled' do
        expect(Gitlab.config.cell).to receive(:enabled).and_return(false)

        expect { base_service }.to raise_error(NotImplementedError)
      end
    end
  end
end
