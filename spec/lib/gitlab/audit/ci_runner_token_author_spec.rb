# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::CiRunnerTokenAuthor do
  describe '.initialize' do
    subject { described_class.new(audit_event) }

    let(:details) {}
    let(:audit_event) { instance_double(AuditEvent, details: details, entity_type: 'Project', entity_path: 'd/e') }

    context 'with runner_authentication_token' do
      let(:details) do
        { runner_authentication_token: 'abc1234567' }
      end

      it 'returns CiRunnerTokenAuthor with expected attributes' do
        is_expected.to have_attributes(id: -1, name: 'Authentication token: abc1234567')
      end
    end

    context 'with runner_registration_token' do
      let(:details) do
        { runner_registration_token: 'abc1234567' }
      end

      it 'returns CiRunnerTokenAuthor with expected attributes' do
        is_expected.to have_attributes(id: -1, name: 'Registration token: abc1234567')
      end
    end

    context 'with runner token missing' do
      let(:details) do
        {}
      end

      it 'raises ArgumentError' do
        expect { subject }.to raise_error ArgumentError, 'Runner token missing'
      end
    end
  end

  describe '#full_path' do
    subject { author.full_path }

    let(:author) { described_class.new(audit_event) }

    context 'with instance registration token' do
      let(:audit_event) { instance_double(AuditEvent, details: { runner_registration_token: 'abc1234567' }, entity_type: 'User', entity_path: nil) }

      it 'returns correct url' do
        is_expected.to eq('/admin/runners')
      end
    end

    context 'with group registration token' do
      let(:audit_event) { instance_double(AuditEvent, details: { runner_registration_token: 'abc1234567' }, entity_type: 'Group', entity_path: 'a/b') }

      it 'returns correct url' do
        expect(::Gitlab::Routing.url_helpers).to receive(:group_settings_ci_cd_path)
          .once
          .with('a/b', { anchor: 'js-runners-settings' })
          .and_return('/path/to/group/runners')

        is_expected.to eq('/path/to/group/runners')
      end
    end

    context 'with project registration token' do
      let(:audit_event) { instance_double(AuditEvent, details: { runner_registration_token: 'abc1234567' }, entity_type: 'Project', entity_path: project.full_path) }
      let(:project) { create(:project) }

      it 'returns correct url' do
        expect(::Gitlab::Routing.url_helpers).to receive(:project_settings_ci_cd_path)
          .once
          .with(project, { anchor: 'js-runners-settings' })
          .and_return('/path/to/project/runners')

        is_expected.to eq('/path/to/project/runners')
      end
    end
  end
end
