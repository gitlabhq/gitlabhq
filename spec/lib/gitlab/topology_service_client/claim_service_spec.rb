# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::ClaimService, feature_category: :cell do
  let(:client_double) { instance_double(Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub) }

  subject(:service) { described_class.instance }

  before do
    allow(Gitlab.config.cell).to receive(:enabled).and_return(true)
  end

  describe 'Singleton' do
    it 'includes Singleton module' do
      expect(described_class.ancestors).to include(Singleton)
    end

    it 'returns the same instance every time' do
      instance1 = described_class.instance
      instance2 = described_class.instance

      expect(instance1).to be(instance2)
      expect(instance1.object_id).to eq(instance2.object_id)
    end
  end

  describe 'method delegation' do
    let(:args) { { foo: 'bar' } }

    before do
      allow(service).to receive(:client).and_return(client_double)
    end

    it 'delegates #begin_update to the client' do
      expect(client_double).to receive(:begin_update).with(args)
      service.begin_update(args)
    end

    it 'delegates #commit_update to the client' do
      expect(client_double).to receive(:commit_update).with(args)
      service.commit_update(args)
    end

    it 'delegates #rollback_update to the client' do
      expect(client_double).to receive(:rollback_update).with(args)
      service.rollback_update(args)
    end
  end

  describe '#service_class' do
    it 'returns the correct gRPC stub class' do
      result = service.send(:service_class)
      expect(result).to eq(Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub)
    end
  end

  describe '#list_leases' do
    let(:cell_id) { 1 }
    let(:mock_response) { Gitlab::Cells::TopologyService::Claims::V1::ListLeasesResponse.new }

    before do
      stub_config_cell({ enabled: true, id: cell_id })
      allow(service).to receive(:client).and_return(client_double)
    end

    using RSpec::Parameterized::TableSyntax

    where(:title, :args, :expected_request, :expected_deadline) do
      cursor  = Google::Protobuf::Any.new
      limit   = 10
      deadline = GRPC::Core::TimeConsts.from_relative_time(5.0)

      req = ->(**opts) do
        Gitlab::Cells::TopologyService::Claims::V1::ListLeasesRequest.new({ cell_id: 1 }.merge(opts))
      end

      [
        [
          "no params",
          {}, # args
          req.call,                           # expected_request
          nil                                 # expected_deadline
        ],
        [
          "with cursor",
          { cursor: cursor },
          req.call(next: cursor),
          nil
        ],
        [
          "with limit",
          { limit: limit },
          req.call(limit: limit),
          nil
        ],
        [
          "with deadline",
          { deadline: deadline },
          req.call,
          deadline
        ],
        [
          "with cursor & limit & deadline",
          { cursor: cursor, limit: limit, deadline: deadline },
          req.call(next: cursor, limit: limit),
          deadline
        ]
      ]
    end

    with_them do
      it 'delegates call to client.list_leases with correct params' do
        expect(client_double)
          .to receive(:list_leases)
          .with(expected_request, deadline: expected_deadline)
          .and_return(mock_response)

        result = service.list_leases(**args)

        expect(result).to eq(mock_response)
      end
    end
  end
end
