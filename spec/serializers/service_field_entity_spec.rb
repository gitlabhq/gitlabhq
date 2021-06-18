# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceFieldEntity do
  let(:request) { double('request') }

  subject { described_class.new(field, request: request, service: integration).as_json }

  before do
    allow(request).to receive(:service).and_return(integration)
  end

  describe '#as_json' do
    context 'Jira Service' do
      let(:integration) { create(:jira_integration) }

      context 'field with type text' do
        let(:field) { integration_field('username') }

        it 'exposes correct attributes' do
          expected_hash = {
            type: 'text',
            name: 'username',
            title: 'Username or Email',
            placeholder: nil,
            help: 'Use a username for server version and an email for cloud version.',
            required: true,
            choices: nil,
            value: 'jira_username'
          }

          is_expected.to eq(expected_hash)
        end
      end

      context 'field with type password' do
        let(:field) { integration_field('password') }

        it 'exposes correct attributes but hides password' do
          expected_hash = {
            type: 'password',
            name: 'password',
            title: 'Enter new password or API token',
            placeholder: nil,
            help: 'Leave blank to use your current password or API token.',
            required: true,
            choices: nil,
            value: 'true'
          }

          is_expected.to eq(expected_hash)
        end
      end
    end

    context 'EmailsOnPush Service' do
      let(:integration) { create(:emails_on_push_integration, send_from_committer_email: '1') }

      context 'field with type checkbox' do
        let(:field) { integration_field('send_from_committer_email') }

        it 'exposes correct attributes and casts value to Boolean' do
          expected_hash = {
            type: 'checkbox',
            name: 'send_from_committer_email',
            title: 'Send from committer',
            placeholder: nil,
            required: nil,
            choices: nil,
            value: 'true'
          }

          is_expected.to include(expected_hash)
          expect(subject[:help]).to include("Send notifications from the committer's email address if the domain matches the domain used by your GitLab instance")
        end
      end

      context 'field with type select' do
        let(:field) { integration_field('branches_to_be_notified') }

        it 'exposes correct attributes' do
          expected_hash = {
            type: 'select',
            name: 'branches_to_be_notified',
            title: nil,
            placeholder: nil,
            required: nil,
            choices: [['All branches', 'all'], ['Default branch', 'default'], ['Protected branches', 'protected'], ['Default branch and protected branches', 'default_and_protected']],
            help: nil,
            value: nil
          }

          is_expected.to eq(expected_hash)
        end
      end
    end
  end

  def integration_field(name)
    integration.global_fields.find { |f| f[:name] == name }
  end
end
