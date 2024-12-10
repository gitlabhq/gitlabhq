# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::CiRunnerTokenAuthor, feature_category: :runner do
  let(:token_args) { details.slice(:runner_authentication_token, :runner_registration_token) }

  describe '.initialize' do
    subject do
      described_class.new(entity_type: 'Project', entity_path: 'd/e', **token_args)
    end

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

      it 'returns token not available' do
        is_expected.to have_attributes(id: -1, name: 'Token not available')
      end
    end
  end

  describe '#full_path' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:details) { { runner_authentication_token: 'grlt-abc1234567' } } # gitleaks:allow
    let(:author) { described_class.new(entity_type: entity_type, entity_path: entity_path, **token_args) }

    subject(:full_path) { author.full_path }

    context 'with instance registration token' do
      let(:details) { { runner_registration_token: 'abc1234567' } }
      let(:entity_type) { 'Gitlab::Audit::InstanceScope' }
      let(:entity_path) { 'gitlab_instance' }

      it 'returns correct url' do
        is_expected.to eq('/admin/runners')
      end
    end

    context 'with group registration token' do
      let(:entity_type) { 'Group' }
      let(:entity_path) { group.full_path }

      it 'returns correct url' do
        expect(::Gitlab::Routing.url_helpers).to receive(:group_runners).with(entity_path).and_return('runners path')

        is_expected.to eq('runners path')
      end
    end

    context 'with project registration token' do
      let(:entity_type) { 'Project' }
      let(:entity_path) { project.full_path }

      it 'returns correct url' do
        expect(::Gitlab::Routing.url_helpers).to receive(:project_settings_ci_cd_path)
          .with(project, { anchor: 'js-runners-settings' })
          .and_return('runners path')

        is_expected.to eq('runners path')
      end
    end
  end
end
