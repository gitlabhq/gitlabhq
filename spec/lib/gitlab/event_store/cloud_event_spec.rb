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
end
