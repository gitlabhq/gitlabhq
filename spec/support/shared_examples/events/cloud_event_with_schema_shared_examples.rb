# frozen_string_literal: true

RSpec.shared_examples 'a cloud event with schema' do |valid_data:, missing_required:, invalid_types:|
  let(:cloud_event_data) do
    {
      specversion: '1.0',
      type: "com.gitlab.merge_requests.approved",
      dataschema: "https://gitlab.com/schemas/merge_requests/approved/v1.0",
      id: SecureRandom.uuid,
      datacontenttype: 'application/json',
      time: Time.current.iso8601,
      source: 'project/1',
      subject: 'merge_request/1',
      gitlab_user_id: 1,
      gitlab_user_username: 'root',
      gitlab_organization_id: 1
    }
  end

  describe '#schema' do
    context 'with valid data' do
      it 'initializes without error' do
        expect { described_class.new(data: cloud_event_data.merge(data: valid_data)) }.not_to raise_error
      end
    end

    context 'with missing required properties' do
      missing_required.each do |field|
        it "raises an error when #{field} is missing" do
          expect { described_class.new(data: cloud_event_data.merge(data: valid_data.except(field))) }
            .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
        end
      end
    end

    context 'with invalid property types' do
      invalid_types.each do |field, invalid_value|
        it "raises an error when #{field} has an invalid type" do
          expect { described_class.new(data: cloud_event_data.merge(data: valid_data.merge(field => invalid_value))) }
            .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
        end
      end
    end
  end
end
