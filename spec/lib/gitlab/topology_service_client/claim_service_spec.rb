# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::ClaimService, feature_category: :cell do
  let(:cell_id) { 1 }
  let(:client_double) { instance_double(Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub) }

  subject(:service) { described_class.instance }

  before do
    stub_config_cell({ enabled: true, id: cell_id })
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

  describe '#service_class' do
    it 'returns the correct gRPC stub class' do
      result = service.send(:service_class)
      expect(result).to eq(Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub)
    end
  end

  describe '#begin_update' do
    let(:request) do
      Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
        create_records: [],
        destroy_records: [],
        cell_id: cell_id
      )
    end

    let(:mock_response) { Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new }

    before do
      allow(service).to receive(:client).and_return(client_double)
    end

    it 'calls client.begin_update with the correct parameters' do
      expect(client_double).to receive(:begin_update).with(request, deadline: nil).and_return(mock_response)

      result = service.begin_update(create_records: [], destroy_records: [])

      expect(result).to eq(mock_response)
    end

    context 'with deadline' do
      let(:deadline) { GRPC::Core::TimeConsts.from_relative_time(5.0) }

      it 'calls client.begin_update with valid parameters' do
        expect(client_double).to receive(:begin_update).with(request, deadline: deadline).and_return(mock_response)

        result = service.begin_update(create_records: [], destroy_records: [], deadline: deadline)

        expect(result).to eq(mock_response)
      end
    end
  end

  describe '#commit_update' do
    let(:lease_uuid) { SecureRandom.uuid }
    let(:request) do
      Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateRequest.new(
        lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease_uuid),
        cell_id: cell_id
      )
    end

    let(:mock_response) { Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateResponse.new }

    before do
      allow(service).to receive(:client).and_return(client_double)
    end

    it 'calls client.commit_update with the correct parameters' do
      expect(client_double).to receive(:commit_update).with(request, deadline: nil).and_return(mock_response)

      result = service.commit_update(lease_uuid)

      expect(result).to eq(mock_response)
    end

    context 'with deadline' do
      let(:deadline) { GRPC::Core::TimeConsts.from_relative_time(5.0) }

      it 'calls client.commit_update with valid parameters' do
        expect(client_double).to receive(:commit_update).with(request, deadline: deadline).and_return(mock_response)

        result = service.commit_update(lease_uuid, deadline: deadline)

        expect(result).to eq(mock_response)
      end
    end
  end

  describe '#rollback_update' do
    let(:lease_uuid) { SecureRandom.uuid }
    let(:request) do
      Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateRequest.new(
        lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease_uuid),
        cell_id: cell_id
      )
    end

    let(:mock_response) { Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateResponse.new }

    before do
      allow(service).to receive(:client).and_return(client_double)
    end

    it 'calls client.rollback_update with the correct parameters' do
      expect(client_double).to receive(:rollback_update).with(request, deadline: nil).and_return(mock_response)

      result = service.rollback_update(lease_uuid)

      expect(result).to eq(mock_response)
    end

    context 'with deadline' do
      let(:deadline) { GRPC::Core::TimeConsts.from_relative_time(5.0) }

      it 'calls client.rollback_update with valid parameters' do
        expect(client_double).to receive(:rollback_update).with(request, deadline: deadline).and_return(mock_response)

        result = service.rollback_update(lease_uuid, deadline: deadline)

        expect(result).to eq(mock_response)
      end
    end
  end

  describe '#list_leases' do
    let(:mock_response) { Gitlab::Cells::TopologyService::Claims::V1::ListLeasesResponse.new }

    before do
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

  describe '#list_records' do
    let(:mock_response) { Gitlab::Cells::TopologyService::Claims::V1::ListRecordsResponse.new }

    before do
      allow(service).to receive(:client).and_return(client_double)
    end

    using RSpec::Parameterized::TableSyntax

    where(:title, :args, :expected_request, :expected_deadline) do
      source_type       = Cells::Claimable::CLAIMS_SOURCE_TYPE::UNSPECIFIED
      bucket_types      = [Cells::Claimable::CLAIMS_SUBJECT_TYPE::UNSPECIFIED]
      source_id_gt = [100].pack("Q>")
      source_id_lte = [200].pack("Q>")
      deadline = GRPC::Core::TimeConsts.from_relative_time(5.0)

      req = ->(**opts) do
        Gitlab::Cells::TopologyService::Claims::V1::ListRecordsRequest.new({ cell_id: 1 }.merge(opts))
      end

      [
        [
          "no params",
          {},
          req.call,
          nil
        ],
        [
          "with source_type",
          { source_type: source_type },
          req.call(source_type: source_type),
          nil
        ],
        [
          "with bucket_types",
          { bucket_types: bucket_types },
          req.call(bucket_types: bucket_types),
          nil
        ],
        [
          "with source_id_gt",
          { source_id_gt: source_id_gt },
          req.call(source_id_gt: source_id_gt),
          nil
        ],
        [
          "with source_id_lte",
          { source_id_lte: source_id_lte },
          req.call(source_id_lte: source_id_lte),
          nil
        ],
        [
          "with deadline",
          { deadline: deadline },
          req.call,
          deadline
        ],
        [
          "with all params",
          {
            source_type: source_type,
            bucket_types: bucket_types,
            source_id_gt: source_id_gt,
            source_id_lte: source_id_lte,
            deadline: deadline
          },
          req.call(
            source_type: source_type,
            bucket_types: bucket_types,
            source_id_gt: source_id_gt,
            source_id_lte: source_id_lte
          ),
          deadline
        ]
      ]
    end

    with_them do
      it 'delegates call to client.list_records with correct params' do
        expect(client_double)
          .to receive(:list_records)
          .with(expected_request, deadline: expected_deadline)
          .and_return(mock_response)

        result = service.list_records(**args)

        expect(result).to eq(mock_response)
      end
    end
  end
end
