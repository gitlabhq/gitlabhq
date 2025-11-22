# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::FrontendStandardContext, feature_category: :service_ping do
  let(:user) { build_stubbed(:user, user_type: 'human') }
  let(:namespace) { build_stubbed(:group) }
  let(:project_id) { 42 }
  let(:hostname) { 'example.com' }
  let(:version) { '17.3.0' }
  let(:instance_id) { SecureRandom.uuid }

  let(:standard_context) do
    Gitlab::Tracking::StandardContext.new(
      user: user,
      project_id: project_id,
      namespace: namespace
    )
  end

  subject(:frontend_context) { described_class.new(standard_context) }

  before do
    allow(Gitlab.config.gitlab).to receive(:host).and_return(hostname)
    allow(Gitlab).to receive(:version_info).and_return(Gitlab::VersionInfo.parse(version))
    allow(Gitlab::GlobalAnonymousId).to receive(:instance_id).and_return(instance_id)
  end

  describe '#to_context' do
    let(:snowplow_context) { frontend_context.to_context }
    let(:json_data) { snowplow_context.to_json.fetch(:data) }

    it 'returns a SnowplowTracker::SelfDescribingJson object' do
      expect(snowplow_context).to be_a(SnowplowTracker::SelfDescribingJson)
    end

    it 'uses the correct schema URL' do
      expect(snowplow_context.to_json[:schema]).to eq(Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL)
    end

    describe 'field filtering' do
      it 'includes all fields from StandardContext except sensitive fields', :freeze_time do
        standard_data = standard_context.to_h
        expected_fields = standard_data.keys - described_class::SENSITIVE_FIELDS

        # Verify all expected fields are present
        expect(json_data.keys).to match_array(expected_fields)

        # Verify non-sensitive fields have the same values
        expected_fields.each do |field|
          expect(json_data[field]).to eq(standard_data[field]),
            "Expected #{field} to match between filtered and standard context"
        end
      end

      it 'excludes all sensitive fields' do
        described_class::SENSITIVE_FIELDS.each do |field|
          expect(json_data).not_to have_key(field)
        end
      end
    end

    context 'with extra data' do
      let(:standard_context) do
        Gitlab::Tracking::StandardContext.new(
          user: user,
          extra_key_1: 'extra value 1',
          extra_key_2: 'extra value 2'
        )
      end

      it 'includes extra data in `extra` hash' do
        expect(json_data[:extra]).to eq(extra_key_1: 'extra value 1', extra_key_2: 'extra value 2')
      end
    end
  end
end
