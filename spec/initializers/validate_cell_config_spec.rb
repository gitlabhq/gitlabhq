# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validate database config', feature_category: :cell do
  include StubENV

  let(:dev_message) do
    "\nMake sure your development environment is up to date.\nFor example, on GDK, run: gdk update\n"
  end

  let(:rails_configuration) { Rails::Application::Configuration.new(Rails.root) }
  let(:valid_topology_service_client_config) do
    {
      address: 'topology-service.gitlab.example.com:443',
      ca_file: '/home/git/gitlab/config/topology-service-ca.pem',
      certificate_file: '/home/git/gitlab/config/topology-service-cert.pem',
      private_key_file: '/home/git/gitlab/config/topology-service-key.pem'
    }
  end

  let(:incomplete_topology_service_client_config) do
    {
      address: '',
      ca_file: '/home/git/gitlab/config/topology-service-ca.pem',
      certificate_file: '/home/git/gitlab/config/topology-service-cert.pem',
      private_key_file: '/home/git/gitlab/config/topology-service-key.pem'
    }
  end

  subject(:validate_config) do
    load Rails.root.join('config/initializers/validate_cell_config.rb')
  end

  before do
    allow(Rails.application).to receive(:config).and_return(rails_configuration)
  end

  shared_examples 'with SKIP_CELL_CONFIG_VALIDATION=true' do
    before do
      stub_env('SKIP_CELL_CONFIG_VALIDATION', 'true')
      # Wrong Cell configuration, because cell.id is missing
      stub_config(cell: { enabled: true, id: nil, topology_service_client: valid_topology_service_client_config })
    end

    it 'does not raise exception' do
      expect { validate_config }.not_to raise_error
    end
  end

  context 'when cell is correctly configured' do
    before do
      stub_config(cell: { id: 1, enabled: true, topology_service_client: valid_topology_service_client_config })
    end

    it 'does not raise exception' do
      expect { validate_config }.not_to raise_error
    end
  end

  context 'when cell is not configured' do
    context 'when cell id is nil' do
      before do
        stub_config(cell: { enabled: false, id: nil })
      end

      it 'does not raise exception' do
        expect { validate_config }.not_to raise_error
      end
    end

    context 'when cell id is not nil' do
      before do
        stub_config(cell: { enabled: false, id: 3 })
      end

      it 'raises an exception' do
        expect { validate_config }.to raise_error("Cell ID is set but Cell is not enabled.#{dev_message}")
      end
    end
  end

  context 'when configuration is invalid' do
    context 'when cell is enabled by cell id is not set' do
      before do
        stub_config(cell: { enabled: true, id: nil, topology_service_client: valid_topology_service_client_config })
      end

      it 'raises exception about missing cell id' do
        expect { validate_config }.to raise_error("Cell ID is not set to a valid positive integer.#{dev_message}")
      end

      it_behaves_like 'with SKIP_CELL_CONFIG_VALIDATION=true'

      context 'when not dev environment' do
        before do
          stub_rails_env('production')
        end

        it 'raises exception about missing cell id' do
          expect { validate_config }.to raise_error("Cell ID is not set to a valid positive integer.")
        end
      end
    end

    context 'when cell is enabled by cell id is not valid' do
      before do
        stub_config(cell: { enabled: true, id: 0, topology_service_client: valid_topology_service_client_config })
      end

      it 'raises exception about missing cell id' do
        expect { validate_config }.to raise_error("Cell ID is not set to a valid positive integer.#{dev_message}")
      end

      it_behaves_like 'with SKIP_CELL_CONFIG_VALIDATION=true'
    end

    context 'when cell is enabled' do
      before do
        stub_config(cell: { enabled: true, id: 1, topology_service_client: incomplete_topology_service_client_config })
      end

      it 'raises exception about missing topology service client config' do
        expect { validate_config }.to raise_error("Topology Service Client setting 'address' is not set.#{dev_message}")
      end

      it_behaves_like 'with SKIP_CELL_CONFIG_VALIDATION=true'
    end
  end
end
