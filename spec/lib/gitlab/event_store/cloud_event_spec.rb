# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EventStore::CloudEvent, feature_category: :code_suggestions do
  let_it_be(:user) { create(:user) }
  let_it_be(:organization) { create(:organization) }

  let(:test_cloud_event_class) do
    Class.new(described_class) do
      event_category :merge_requests
      event_type :approved

      def data_schema
        {
          'type' => 'object',
          'properties' => {
            'merge_request_id' => { 'type' => 'number' }
          },
          'required' => ['merge_request_id']
        }
      end
    end
  end

  let(:event_data) do
    {
      specversion: '1.0',
      type: 'com.gitlab.merge_requests.assigned_reviewers',
      dataschema: 'https://gitlab.com/schemas/merge_requests/assigned_reviewers/v1.0',
      id: SecureRandom.uuid,
      datacontenttype: 'application/json',
      time: Time.current.iso8601,
      source: '/projects/1/merge_requests/1',
      subject: '/merge_requests/1',
      gitlab_user_id: user.id,
      gitlab_user_username: user.username,
      gitlab_organization_id: organization.id,
      data: { merge_request_id: 1 }
    }
  end

  subject(:cloud_event) { test_cloud_event_class.new(data: event_data) }

  around do |example|
    original_registry = described_class::REGISTRY.dup
    example.run
  ensure
    described_class::REGISTRY.clear
    described_class::REGISTRY.merge!(original_registry)
  end

  describe '#initialize' do
    it 'creates a valid event' do
      expect(cloud_event).to be_a(described_class)
      expect(cloud_event.data[:specversion]).to eq('1.0')
    end

    context 'when a required field is missing' do
      before do
        event_data.delete(:specversion)
      end

      it 'raises an InvalidEvent error' do
        expect { cloud_event }.to raise_error(Gitlab::EventStore::InvalidEvent)
      end
    end

    context 'when data field is missing' do
      before do
        event_data.delete(:data)
      end

      it 'raises an InvalidEvent error' do
        expect { cloud_event }.to raise_error(Gitlab::EventStore::InvalidEvent)
      end
    end
  end

  describe '#id' do
    it 'returns the id of the event' do
      expect(cloud_event.id).to eq(cloud_event.data[:id])
    end
  end

  describe '#current_user' do
    it 'returns the user matching gitlab_user_id' do
      expect(cloud_event.current_user).to eq(user)
    end

    it 'memoizes the result' do
      expect(User).to receive(:find_by_id).once.and_call_original

      2.times { cloud_event.current_user }
    end
  end

  describe '#organization' do
    it 'returns the organization matching organization_id' do
      expect(cloud_event.organization).to eq(organization)
    end

    it 'memoizes the result' do
      expect(Organizations::Organization).to receive(:find_by_id).once.and_call_original

      2.times { cloud_event.organization }
    end
  end

  describe '#event_category' do
    it 'extracts the event category from the type' do
      expect(cloud_event.event_category).to eq(:merge_requests)
    end
  end

  describe '#event_type' do
    it 'extracts the event type from the type' do
      expect(cloud_event.event_type).to eq(:approved)
    end
  end

  describe '#event_data' do
    it 'returns the data field from the event' do
      expect(cloud_event.event_data).to eq({ merge_request_id: 1 })
    end
  end

  describe '#schema' do
    it 'returns a valid JSON schema object' do
      schema = cloud_event.schema

      expect(schema).to be_a(Hash)
      expect(schema['type']).to eq('object')
      expect(schema['properties']).to be_a(Hash)
      expect(schema['required']).to be_an(Array)
    end

    it 'includes all required fields' do
      required_fields = %w[specversion type source id time datacontenttype dataschema subject data
        gitlab_user_id gitlab_user_username gitlab_organization_id]

      expect(cloud_event.schema['required']).to match_array(required_fields)
    end

    it 'defines properties for all required fields' do
      schema = cloud_event.schema
      required_fields = schema['required']

      required_fields.each do |field|
        expect(schema['properties']).to have_key(field)
      end
    end

    it 'defines correct types for properties' do
      schema = cloud_event.schema

      expect(schema['properties']['specversion']['type']).to eq('string')
      expect(schema['properties']['type']['type']).to eq('string')
      expect(schema['properties']['source']['type']).to eq('string')
      expect(schema['properties']['id']['type']).to eq('string')
      expect(schema['properties']['gitlab_user_id']['type']).to eq('number')
      expect(schema['properties']['gitlab_user_username']['type']).to eq('string')
      expect(schema['properties']['gitlab_organization_id']['type']).to eq('number')
      expect(schema['properties']['time']['type']).to eq('string')
      expect(schema['properties']['time']['format']).to eq('date-time')
      expect(schema['properties']['datacontenttype']['type']).to eq('string')
      expect(schema['properties']['dataschema']['type']).to eq('string')
      expect(schema['properties']['dataschema']['format']).to eq('uri')
      expect(schema['properties']['subject']['type']).to eq('string')
      expect(schema['properties']['data']['type']).to eq('object')
    end
  end

  describe 'cannot instantiate an object from this class' do
    it 'raises NotImplementedError' do
      unimplemented_class = Class.new(described_class)
      expect { unimplemented_class.new(data: event_data) }.to raise_error(NotImplementedError)
    end
  end

  describe '.event_category' do
    it 'sets the event category class attribute' do
      test_class = Class.new(described_class) do
        def data_schema
          {}
        end
      end
      test_class.event_category('test_category')

      expect(test_class.get_event_category).to eq('test_category')
    end
  end

  describe '.event_type' do
    it 'sets the event type class attribute' do
      test_class = Class.new(described_class) do
        def data_schema
          {}
        end
      end
      test_class.event_type('test_type')

      expect(test_class.get_event_type).to eq('test_type')
    end
  end

  describe '.get_event_category' do
    it 'returns the event category' do
      test_class = Class.new(described_class) do
        def data_schema
          {}
        end
      end
      test_class.event_category('test_category')

      expect(test_class.get_event_category).to eq('test_category')
    end
  end

  describe '.get_event_type' do
    it 'returns the event type' do
      test_class = Class.new(described_class) do
        def data_schema
          {}
        end
      end
      test_class.event_type('test_type')

      expect(test_class.get_event_type).to eq('test_type')
    end
  end

  describe '.build_cloud_event' do
    let(:source) { '/projects/1/merge_requests/1' }
    let(:subject_path) { '/merge_requests/1' }
    let(:event_data_payload) { { merge_request_id: 1 } }

    it 'builds a valid cloud event' do
      test_class = Class.new(described_class) do
        def data_schema
          {}
        end
      end
      test_class.event_category('merge_requests')
      test_class.event_type('assigned_reviewers')

      cloud_event = test_class.build_cloud_event(
        source: source,
        subject: subject_path,
        current_user: user,
        organization: organization,
        event_data: event_data_payload
      )
      data = cloud_event.data

      expect(data).to be_a(Hash)
      expect(data[:specversion]).to eq('1.0')
      expect(data[:type]).to eq('com.gitlab.merge_requests.assigned_reviewers')
      expect(data[:dataschema]).to eq('https://gitlab.com/schemas/merge_requests/assigned_reviewers/v1.0')
      expect(data[:datacontenttype]).to eq('application/json')
      expect(data[:source]).to eq(source)
      expect(data[:subject]).to eq(subject_path)
      expect(data[:gitlab_user_id]).to eq(user.id)
      expect(data[:gitlab_user_username]).to eq(user.username)
      expect(data[:gitlab_organization_id]).to eq(organization.id)
      expect(cloud_event.event_data).to eq(event_data_payload)
    end

    it 'generates a unique id for each call' do
      test_class = Class.new(described_class) do
        def data_schema
          {}
        end
      end
      test_class.event_category('merge_requests')
      test_class.event_type('assigned_reviewers')

      result1 = test_class.build_cloud_event(
        source: source,
        subject: subject_path,
        current_user: user,
        organization: organization,
        event_data: event_data_payload
      )

      result2 = test_class.build_cloud_event(
        source: source,
        subject: subject_path,
        current_user: user,
        organization: organization,
        event_data: event_data_payload
      )

      expect(result1.id).not_to eq(result2.id)
    end

    it 'generates a valid ISO8601 timestamp' do
      test_class = Class.new(described_class) do
        def data_schema
          {}
        end
      end
      test_class.event_category('merge_requests')
      test_class.event_type('assigned_reviewers')

      cloud_event = test_class.build_cloud_event(
        source: source,
        subject: subject_path,
        current_user: user,
        organization: organization,
        event_data: event_data_payload
      )

      expect { Time.iso8601(cloud_event.data[:time]) }.not_to raise_error
    end

    it 'accepts empty event_data' do
      test_class = Class.new(described_class) do
        def data_schema
          {}
        end
      end
      test_class.event_category('merge_requests')
      test_class.event_type('assigned_reviewers')

      cloud_event = test_class.build_cloud_event(
        source: source,
        subject: subject_path,
        current_user: user,
        organization: organization
      )

      expect(cloud_event.event_data).to eq({})
    end
  end

  describe '#to_proto' do
    subject(:proto) { cloud_event.to_proto }

    it 'returns a Gitlab::Agent::Event::CloudEvent' do
      expect(proto).to be_a(Gitlab::Agent::Event::CloudEvent)
    end

    it 'maps required spec fields to top-level proto fields', :aggregate_failures do
      expect(proto.id).to eq(event_data[:id])
      expect(proto.source).to eq(event_data[:source])
      expect(proto.spec_version).to eq(event_data[:specversion])
      expect(proto.type).to eq(event_data[:type])
    end

    it 'JSON-encodes the event payload into text_data' do
      expect(proto.text_data).to eq(event_data[:data].to_json)
    end

    it 'maps string attributes into the attributes map as ce_string values', :aggregate_failures do
      %i[datacontenttype dataschema gitlab_user_username subject time].each do |key|
        expect(proto.attributes[key.to_s].ce_string).to eq(event_data[key].to_s)
      end
    end

    it 'maps integer attributes into the attributes map as ce_integer values', :aggregate_failures do
      expect(proto.attributes['gitlab_user_id'].ce_integer).to eq(event_data[:gitlab_user_id])
      expect(proto.attributes['gitlab_organization_id'].ce_integer).to eq(event_data[:gitlab_organization_id])
    end

    it 'round-trips through protobuf serialization', :aggregate_failures do
      serialized = Gitlab::Agent::Event::CloudEvent.encode(proto)
      decoded = Gitlab::Agent::Event::CloudEvent.decode(serialized)

      expect(decoded.id).to eq(proto.id)
      expect(decoded.source).to eq(proto.source)
      expect(decoded.spec_version).to eq(proto.spec_version)
      expect(decoded.type).to eq(proto.type)
      expect(decoded.text_data).to eq(proto.text_data)
      expect(decoded.attributes.keys).to match_array(proto.attributes.keys)
    end
  end

  describe '.register' do
    it 'maps a type string to a CloudEvent subclass' do
      described_class.register('com.example.x', test_cloud_event_class)

      expect(described_class.lookup('com.example.x')).to eq(test_cloud_event_class)
    end

    it 'returns the registered class' do
      expect(described_class.register('com.example.x', test_cloud_event_class)).to eq(test_cloud_event_class)
    end

    it 'rejects a non-String type' do
      expect { described_class.register(:symbol, test_cloud_event_class) }
        .to raise_error(ArgumentError, /type must be a String/)
    end

    it 'rejects a non-Class klass' do
      expect { described_class.register('com.example.x', 'not a class') }
        .to raise_error(ArgumentError, /must be a Gitlab::EventStore::CloudEvent subclass/)
    end

    it 'rejects a class that is not a CloudEvent subclass' do
      expect { described_class.register('com.example.x', String) }
        .to raise_error(ArgumentError, /must be a Gitlab::EventStore::CloudEvent subclass/)
    end
  end

  describe '.lookup' do
    it 'returns the registered class for a known type' do
      described_class.register('com.example.x', test_cloud_event_class)

      expect(described_class.lookup('com.example.x')).to eq(test_cloud_event_class)
    end

    it 'returns nil for an unregistered type' do
      expect(described_class.lookup('com.example.never_registered')).to be_nil
    end
  end

  describe '.from_proto' do
    let(:registered_type) { 'com.gitlab.merge_requests.assigned_reviewers' }

    before do
      described_class.register(registered_type, test_cloud_event_class)
    end

    context 'when the type is registered' do
      let(:proto) { cloud_event.to_proto }

      subject(:result) { described_class.from_proto(proto) }

      it 'returns an instance of the registered class' do
        expect(result).to be_a(test_cloud_event_class)
      end

      it 'restores the required spec fields', :aggregate_failures do
        expect(result.data[:id]).to eq(event_data[:id])
        expect(result.data[:source]).to eq(event_data[:source])
        expect(result.data[:specversion]).to eq(event_data[:specversion])
        expect(result.data[:type]).to eq(event_data[:type])
      end

      it 'unwraps ce_string attributes', :aggregate_failures do
        %i[datacontenttype dataschema gitlab_user_username subject time].each do |key|
          expect(result.data[key]).to eq(event_data[key].to_s)
        end
      end

      it 'unwraps ce_integer attributes', :aggregate_failures do
        expect(result.data[:gitlab_user_id]).to eq(event_data[:gitlab_user_id])
        expect(result.data[:gitlab_organization_id]).to eq(event_data[:gitlab_organization_id])
      end

      it 'JSON-decodes text_data into the payload' do
        expect(result.event_data).to eq(event_data[:data])
      end
    end

    context 'when text_data is empty' do
      let(:empty_payload_type) { 'com.gitlab.merge_requests.empty' }

      let(:empty_payload_class) do
        Class.new(described_class) do
          event_category :merge_requests
          event_type :empty

          def data_schema
            { 'type' => 'object' }
          end
        end
      end

      let(:empty_payload_event) do
        empty_payload_class.new(data: event_data.merge(type: empty_payload_type, data: {}))
      end

      before do
        described_class.register(empty_payload_type, empty_payload_class)
      end

      it 'decodes an empty text_data into an empty payload' do
        proto = empty_payload_event.to_proto
        proto.text_data = ''

        expect(described_class.from_proto(proto).event_data).to eq({})
      end
    end

    context 'when the type is not registered' do
      let(:proto) { build_proto_event(type: 'com.example.never_registered') }

      it 'raises UnknownCloudEventTypeError' do
        expect { described_class.from_proto(proto) }
          .to raise_error(described_class::UnknownCloudEventTypeError,
            /no registered class for CloudEvent type/)
      end
    end

    context 'when the payload uses binary_data' do
      let(:proto) { build_proto_event(type: registered_type, binary_data: 'some bytes') }

      it 'raises UnsupportedPayloadError' do
        expect { described_class.from_proto(proto) }
          .to raise_error(described_class::UnsupportedPayloadError, /only text_data is supported/)
      end
    end

    context 'when an attribute uses an unsupported variant' do
      let(:proto) do
        build_proto_event(
          type: registered_type,
          attributes: { 'subject' => attribute_value(ce_boolean: true) }
        )
      end

      it 'raises UnsupportedPayloadError' do
        expect { described_class.from_proto(proto) }
          .to raise_error(described_class::UnsupportedPayloadError, /unsupported attribute variant/)
      end
    end

    context 'when the proto is missing a required attribute' do
      let(:proto) do
        full = cloud_event.to_proto
        full.attributes.delete('subject')
        full
      end

      it 'raises InvalidEvent from schema validation' do
        expect { described_class.from_proto(proto) }
          .to raise_error(Gitlab::EventStore::InvalidEvent)
      end
    end

    context 'when the attributes map smuggles required spec fields' do
      let(:proto) do
        full = cloud_event.to_proto
        full.attributes['id'] = attribute_value(ce_string: 'smuggled')
        full.attributes['type'] = attribute_value(ce_string: 'smuggled')
        full
      end

      it 'keeps the explicitly-decoded spec fields', :aggregate_failures do
        result = described_class.from_proto(proto)

        expect(result.data[:id]).to eq(event_data[:id])
        expect(result.data[:type]).to eq(event_data[:type])
      end
    end

    context 'when round-tripping a real event through to_proto and from_proto' do
      subject(:round_tripped) { described_class.from_proto(cloud_event.to_proto) }

      it 'reconstructs an equivalent event', :aggregate_failures do
        expect(round_tripped).to be_a(test_cloud_event_class)
        expect(round_tripped.data[:type]).to eq(cloud_event.data[:type])
        expect(round_tripped.event_category).to eq(cloud_event.event_category)
        expect(round_tripped.event_type).to eq(cloud_event.event_type)
        expect(round_tripped.event_data).to eq(cloud_event.event_data)
      end

      it 'preserves the attribute values', :aggregate_failures do
        %i[
          datacontenttype dataschema gitlab_organization_id gitlab_user_id
          gitlab_user_username subject time
        ].each do |key|
          expect(round_tripped.data[key]).to eq(cloud_event.data[key])
        end
      end
    end
  end

  def build_proto_event(
    type:, id: SecureRandom.uuid, source: '/projects/1/merge_requests/1',
    spec_version: '1.0', attributes: {}, text_data: nil, binary_data: nil)
    Gitlab::Agent::Event::CloudEvent.new(
      id: id,
      source: source,
      spec_version: spec_version,
      type: type,
      attributes: attributes,
      text_data: text_data,
      binary_data: binary_data
    )
  end

  def attribute_value(**args)
    Gitlab::Agent::Event::CloudEvent::CloudEventAttributeValue.new(**args)
  end
end
