# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::BaseService, feature_category: :cell do
  subject(:base_service) { described_class.new }

  describe '#initialize' do
    context 'when topology service is disabled' do
      it 'raises an error when topology service is not enabled' do
        expect(Gitlab.config.cell.topology_service).to receive(:enabled).and_return(false)

        expect { base_service }.to raise_error(NotImplementedError)
      end
    end
  end
end
