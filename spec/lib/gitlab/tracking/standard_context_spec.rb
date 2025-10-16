# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::StandardContext, feature_category: :service_ping do
  let(:snowplow_context) { subject.to_context }

  describe '#to_context' do
    context 'environment' do
      shared_examples 'contains environment' do |expected_environment|
        it 'contains environment' do
          expect(snowplow_context.to_json.dig(:data, :environment)).to eq(expected_environment)
        end
      end

      context 'development or test' do
        include_examples 'contains environment', 'development'
      end

      context 'staging' do
        before do
          stub_config_setting(url: Gitlab::Saas.staging_com_url)
        end

        include_examples 'contains environment', 'staging'
      end

      context 'production' do
        before do
          stub_config_setting(url: Gitlab::Saas.com_url)
        end

        include_examples 'contains environment', 'production'
      end

      context 'org' do
        before do
          stub_config_setting(url: Gitlab::Saas.dev_url)
        end

        include_examples 'contains environment', 'org'
      end

      context 'other self-managed instance' do
        before do
          stub_rails_env('production')
        end

        include_examples 'contains environment', 'self-managed'
      end
    end

    it 'contains source' do
      expect(snowplow_context.to_json.dig(:data, :source)).to eq(described_class::GITLAB_RAILS_SOURCE)
    end

    it 'contains context_generated_at timestamp', :freeze_time do
      expect(snowplow_context.to_json.dig(:data, :context_generated_at)).to eq(Time.current)
    end

    it 'contains standard properties' do
      standard_properties = [:user_id, :project_id, :namespace_id, :plan, :unique_instance_id, :instance_id, :realm]
      expect(snowplow_context.to_json[:data].keys).to include(*standard_properties)
    end

    context 'with standard properties' do
      let(:user) { build_stubbed(:user, user_type: 'human') }
      let(:top_level_group) { create(:group) }
      let(:subgroup1) { create(:group, parent: top_level_group) }
      let(:subgroup2) { create(:group, parent: subgroup1) }
      let(:bottom_level_group) { create(:group, parent: subgroup2) }
      let(:project_id) { 2 }
      let(:namespace) { bottom_level_group }
      let(:hostname) { 'example.com' }
      let(:version) { '17.3.0' }
      let(:json_data) { snowplow_context.to_json.fetch(:data) }
      let(:instance_id) { SecureRandom.uuid }

      before do
        allow(Gitlab.config.gitlab).to receive(:host).and_return(hostname)
        allow(Gitlab).to receive(:version_info).and_return(Gitlab::VersionInfo.parse(version))
        allow(Gitlab::GlobalAnonymousId).to receive(:instance_id).and_return(instance_id)
      end

      subject do
        described_class.new(user: user, project_id: project_id, namespace: namespace)
      end

      it 'holds the correct values', :aggregate_failures do
        expect(json_data[:is_gitlab_team_member]).to eq(nil)
        expect(json_data[:project_id]).to eq(project_id)
        expect(json_data[:namespace_id]).to eq(namespace.id)
        expect(json_data[:ultimate_parent_namespace_id]).to eq(top_level_group.id)
        expect(json_data[:plan]).to eq('free')
        expect(json_data[:host_name]).to eq(hostname)
        expect(json_data[:instance_version]).to eq(version)
        expect(json_data[:correlation_id]).to eq(Labkit::Correlation::CorrelationId.current_or_new_id)
        expect(json_data[:global_user_id]).to eq(Gitlab::GlobalAnonymousId.user_id(user))
        expect(json_data[:unique_instance_id]).to eq(Gitlab::GlobalAnonymousId.instance_uuid)
        expect(json_data[:user_type]).to eq(user.user_type)
        expect(json_data[:instance_id]).to eq(instance_id)
        expect(json_data[:realm]).to eq(described_class::GITLAB_REALM_SELF_MANAGED)
      end

      describe 'user_id' do
        let(:hashed_user_id) { 'sha256_of_user_id' }

        before do
          allow(Gitlab::CryptoHelper).to receive(:sha256).and_return(hashed_user_id)
        end

        context 'when user is nil' do
          subject { described_class.new(user: nil) }

          it 'pass it to the context' do
            expect(json_data[:user_id]).to be_nil
          end
        end

        context 'when user is an instance of User' do
          it 'hold the pseudonymized user id value', :aggregate_failures do
            expect(json_data[:user_id]).to eq(hashed_user_id)
            expect(json_data[:user_id]).not_to eq(user.id)
            expect(Gitlab::CryptoHelper).to have_received(:sha256).with(user.id)
          end
        end
      end
    end

    context 'with extra data' do
      subject { described_class.new(extra_key_1: 'extra value 1', extra_key_2: 'extra value 2') }

      it 'includes extra data in `extra` hash' do
        expect(snowplow_context.to_json.dig(:data, :extra)).to eq(extra_key_1: 'extra value 1', extra_key_2: 'extra value 2')
      end
    end

    context 'without extra data' do
      it 'contains an empty `extra` hash' do
        expect(snowplow_context.to_json.dig(:data, :extra)).to be_empty
      end
    end

    context 'with incorrect argument type' do
      subject { described_class.new(project_id: "a string") }

      it 'does call `track_and_raise_for_dev_exception`' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        snowplow_context
      end
    end
  end
end
