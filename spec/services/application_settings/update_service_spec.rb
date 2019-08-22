# frozen_string_literal: true

require 'spec_helper'

describe ApplicationSettings::UpdateService do
  include ExternalAuthorizationServiceHelpers

  let(:application_settings) { create(:application_setting) }
  let(:admin) { create(:user, :admin) }
  let(:params) { {} }

  subject { described_class.new(application_settings, admin, params) }

  before do
    # So the caching behaves like it would in production
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    # Creating these settings first ensures they're used by other factories
    application_settings
  end

  describe 'updating terms' do
    context 'when the passed terms are blank' do
      let(:params) { { terms: '' } }

      it 'does not create terms' do
        expect { subject.execute }.not_to change { ApplicationSetting::Term.count }
      end
    end

    context 'when passing terms' do
      let(:params) { { terms: 'Be nice!  ' } }

      it 'creates the terms' do
        expect { subject.execute }.to change { ApplicationSetting::Term.count }.by(1)
      end

      it 'does not create terms if they are the same as the existing ones' do
        create(:term, terms: 'Be nice!')

        expect { subject.execute }.not_to change { ApplicationSetting::Term.count }
      end

      it 'updates terms if they already existed' do
        create(:term, terms: 'Other terms')

        subject.execute

        expect(application_settings.terms).to eq('Be nice!')
      end

      it 'Only queries once when the terms are changed' do
        create(:term, terms: 'Other terms')
        expect(application_settings.terms).to eq('Other terms')

        subject.execute

        expect(application_settings.terms).to eq('Be nice!')
        expect { 2.times { application_settings.terms } }
          .not_to exceed_query_limit(0)
      end
    end
  end

  describe 'updating outbound_local_requests_whitelist' do
    context 'when params is blank' do
      let(:params) { {} }

      it 'does not add to whitelist' do
        expect { subject.execute }.not_to change {
          application_settings.outbound_local_requests_whitelist
        }
      end
    end

    context 'when param add_to_outbound_local_requests_whitelist contains values' do
      before do
        application_settings.outbound_local_requests_whitelist = ['127.0.0.1']
      end

      let(:params) { { add_to_outbound_local_requests_whitelist: ['example.com', ''] } }

      it 'adds to whitelist' do
        expect { subject.execute }.to change {
          application_settings.outbound_local_requests_whitelist
        }

        expect(application_settings.outbound_local_requests_whitelist).to contain_exactly(
          '127.0.0.1', 'example.com'
        )
      end
    end

    context 'when param outbound_local_requests_whitelist_raw is passed' do
      before do
        application_settings.outbound_local_requests_whitelist = ['127.0.0.1']
      end

      let(:params) { { outbound_local_requests_whitelist_raw: 'example.com;gitlab.com' } }

      it 'overwrites the existing whitelist' do
        expect { subject.execute }.to change {
          application_settings.outbound_local_requests_whitelist
        }

        expect(application_settings.outbound_local_requests_whitelist).to contain_exactly(
          'example.com', 'gitlab.com'
        )
      end
    end
  end

  describe 'performance bar settings' do
    using RSpec::Parameterized::TableSyntax

    where(:params_performance_bar_enabled,
      :params_performance_bar_allowed_group_path,
      :previous_performance_bar_allowed_group_id,
      :expected_performance_bar_allowed_group_id) do
      true | '' | nil | nil
      true | '' | 42_000_000 | nil
      true | nil | nil | nil
      true | nil | 42_000_000 | nil
      true | 'foo' | nil | nil
      true | 'foo' | 42_000_000 | nil
      true | 'group_a' | nil | 42_000_000
      true | 'group_b' | 42_000_000 | 43_000_000
      true | 'group_a' | 42_000_000 | 42_000_000
      false | '' | nil | nil
      false | '' | 42_000_000 | nil
      false | nil | nil | nil
      false | nil | 42_000_000 | nil
      false | 'foo' | nil | nil
      false | 'foo' | 42_000_000 | nil
      false | 'group_a' | nil | nil
      false | 'group_b' | 42_000_000 | nil
      false | 'group_a' | 42_000_000 | nil
    end

    with_them do
      let(:params) do
        {
          performance_bar_enabled: params_performance_bar_enabled,
          performance_bar_allowed_group_path: params_performance_bar_allowed_group_path
        }
      end

      before do
        if previous_performance_bar_allowed_group_id == 42_000_000 || params_performance_bar_allowed_group_path == 'group_a'
          create(:group, id: 42_000_000, path: 'group_a')
        end

        if expected_performance_bar_allowed_group_id == 43_000_000 || params_performance_bar_allowed_group_path == 'group_b'
          create(:group, id: 43_000_000, path: 'group_b')
        end

        application_settings.update!(performance_bar_allowed_group_id: previous_performance_bar_allowed_group_id)
      end

      it 'sets performance_bar_allowed_group_id when present and performance_bar_enabled == true' do
        expect(application_settings.performance_bar_allowed_group_id).to eq(previous_performance_bar_allowed_group_id)

        if previous_performance_bar_allowed_group_id != expected_performance_bar_allowed_group_id
          expect { subject.execute }
            .to change(application_settings, :performance_bar_allowed_group_id)
            .from(previous_performance_bar_allowed_group_id).to(expected_performance_bar_allowed_group_id)
        else
          expect { subject.execute }
            .not_to change(application_settings, :performance_bar_allowed_group_id)
        end
      end
    end

    context 'when :performance_bar_allowed_group_path is not present' do
      let(:group) { create(:group) }

      before do
        application_settings.update!(performance_bar_allowed_group_id: group.id)
      end

      it 'does not change the performance bar settings' do
        expect { subject.execute }
          .not_to change(application_settings, :performance_bar_allowed_group_id)
      end
    end

    context 'when :performance_bar_enabled is not present' do
      let(:group) { create(:group) }
      let(:params) { { performance_bar_allowed_group_path: group.full_path } }

      it 'implicitely defaults to true' do
        expect { subject.execute }
          .to change(application_settings, :performance_bar_allowed_group_id)
          .from(nil).to(group.id)
      end
    end
  end

  context 'when external authorization is enabled' do
    before do
      enable_external_authorization_service_check
    end

    it 'does not validate labels if external authorization gets disabled' do
      expect_any_instance_of(described_class).not_to receive(:validate_classification_label)

      described_class.new(application_settings, admin, { external_authorization_service_enabled: false }).execute
    end

    it 'does validate labels if external authorization gets enabled ' do
      expect_any_instance_of(described_class).to receive(:validate_classification_label)

      described_class.new(application_settings, admin, { external_authorization_service_enabled: true }).execute
    end

    it 'does validate labels if external authorization is left unchanged' do
      expect_any_instance_of(described_class).to receive(:validate_classification_label)

      described_class.new(application_settings, admin, { external_authorization_service_default_label: 'new-label' }).execute
    end

    it 'does not save the settings with an error if the service denies access' do
      expect(::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(admin, 'new-label') { false }

      described_class.new(application_settings, admin, { external_authorization_service_default_label: 'new-label' }).execute

      expect(application_settings.errors[:external_authorization_service_default_label]).to be_present
    end

    it 'saves the setting when the user has access to the label' do
      expect(::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(admin, 'new-label') { true }

      described_class.new(application_settings, admin, { external_authorization_service_default_label: 'new-label' }).execute

      # Read the attribute directly to avoid the stub from
      # `enable_external_authorization_service_check`
      expect(application_settings[:external_authorization_service_default_label]).to eq('new-label')
    end

    it 'does not validate the label if it was not passed' do
      expect(::Gitlab::ExternalAuthorization)
        .not_to receive(:access_allowed?)

      described_class.new(application_settings, admin, { home_page_url: 'http://foo.bar' }).execute
    end
  end

  context 'when raw_blob_request_limit is passsed' do
    let(:params) do
      {
        raw_blob_request_limit: 600
      }
    end

    it 'updates raw_blob_request_limit value' do
      subject.execute

      application_settings.reload

      expect(application_settings.raw_blob_request_limit).to eq(600)
    end
  end
end
