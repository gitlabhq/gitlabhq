# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::Emails, feature_category: :service_desk do
  let_it_be(:project, reload: true) { create(:project, :service_desk_enabled) }
  let(:emails) { described_class.new(project) }

  describe '#address' do
    subject(:address) { emails.address }

    shared_examples 'with incoming email address' do
      context 'when incoming email is enabled' do
        before do
          config = double(::GitlabSettings::Settings, enabled: true, address: 'test+%{key}@mail.com') # rubocop: disable RSpec/VerifiedDoubles -- Settings defines methods dynamically
          allow(::Gitlab.config).to receive(:incoming_email).and_return(config)
        end

        it 'uses project full path as service desk address key' do
          expect(address).to eq("test+#{project.full_path_slug}-#{project.project_id}-issue-@mail.com")
        end
      end

      context 'when incoming email is disabled' do
        before do
          config = double(::GitlabSettings::Settings, enabled: false) # rubocop: disable RSpec/VerifiedDoubles -- Settings defines methods dynamically
          allow(::Gitlab.config).to receive(:incoming_email).and_return(config)
        end

        it 'uses project full path as service desk address key' do
          expect(address).to be_nil
        end
      end
    end

    context 'when service_desk_email is disabled' do
      before do
        allow(::Gitlab::Email::ServiceDeskEmail).to receive(:enabled?).and_return(false)
      end

      it_behaves_like 'with incoming email address'
    end

    context 'when service_desk_email is enabled' do
      before do
        config = double(::GitlabSettings::Settings, enabled: true, address: 'foo+%{key}@bar.com') # rubocop: disable RSpec/VerifiedDoubles -- Settings defines methods dynamically
        allow(::Gitlab::Email::ServiceDeskEmail).to receive(:config).and_return(config)
      end

      context 'when project_key is set' do
        it 'returns Service Desk alias address including the project_key' do
          create(:service_desk_setting, project: project, project_key: 'key1')

          expect(address).to eq("foo+#{project.full_path_slug}-key1@bar.com")
        end
      end

      context 'when project_key is not set' do
        it 'returns Service Desk alias address including the project full path' do
          expect(address).to eq("foo+#{project.full_path_slug}-#{project.project_id}-issue-@bar.com")
        end
      end
    end

    context 'when custom email is enabled' do
      let(:custom_email) { 'support@example.com' }

      before do
        setting = ServiceDeskSetting.new(project: project, custom_email: custom_email, custom_email_enabled: true)
        allow(project).to receive(:service_desk_setting).and_return(setting)
      end

      it 'returns custom email address' do
        expect(address).to eq(custom_email)
      end
    end
  end

  describe '#default_subaddress_part' do
    subject(:default_subaddress_part) { emails.default_subaddress_part }

    it 'contains the full path slug, project id and default suffix' do
      is_expected.to eq("#{project.full_path_slug}-#{project.id}-issue-")
    end
  end
end
