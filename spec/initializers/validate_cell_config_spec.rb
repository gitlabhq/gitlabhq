# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validate database config', feature_category: :cell do
  include StubENV

  let(:rails_configuration) { Rails::Application::Configuration.new(Rails.root) }

  subject(:validate_config) do
    load Rails.root.join('config/initializers/validate_cell_config.rb')
  end

  before do
    allow(Rails.application).to receive(:config).and_return(rails_configuration)
  end

  shared_examples 'with SKIP_CELL_CONFIG_VALIDATION=true' do
    before do
      stub_env('SKIP_CELL_CONFIG_VALIDATION', 'true')
    end

    it 'does not raise exception' do
      expect { validate_config }.not_to raise_error
    end
  end

  context 'when topology service is correctly configured' do
    before do
      stub_config(cell: { id: 1, topology_service: { enabled: true } })
    end

    it 'does not raise exception' do
      expect { validate_config }.not_to raise_error
    end
  end

  context 'when topology service is not configured' do
    before do
      stub_config(cell: { id: nil, topology_service: { enabled: false } })
    end

    it 'does not raise exception' do
      expect { validate_config }.not_to raise_error
    end
  end

  context 'when configuration is wrong' do
    context 'when only cell.id is configured' do
      before do
        stub_config(cell: { id: 1, topology_service: { enabled: false } })
      end

      it 'does not raise exception' do
        expect { validate_config }.to raise_error("Topology Service is not configured, but Cell ID is set")
      end

      it_behaves_like 'with SKIP_CELL_CONFIG_VALIDATION=true'
    end

    context 'when only topology service is enabled' do
      before do
        stub_config(cell: { id: nil, topology_service: { enabled: true } })
      end

      it 'does not raise exception' do
        expect { validate_config }.to raise_error("Topology Service is enabled, but Cell ID is not set")
      end

      it_behaves_like 'with SKIP_CELL_CONFIG_VALIDATION=true'
    end
  end
end
