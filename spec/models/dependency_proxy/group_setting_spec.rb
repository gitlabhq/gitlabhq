# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::GroupSetting, type: :model, feature_category: :virtual_registry do
  subject(:setting) { build(:dependency_proxy_group_setting) }

  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'default values' do
    it { is_expected.to be_enabled }
    it { expect(described_class.new(enabled: false)).not_to be_enabled }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:identity) }
    it { is_expected.to validate_presence_of(:secret) }
    it { is_expected.to validate_length_of(:identity).is_at_most(255) }
    it { is_expected.to validate_length_of(:secret).is_at_most(255) }

    context 'for identity and secret cross validation' do
      using RSpec::Parameterized::TableSyntax

      where(:identity, :secret, :valid) do
        nil | nil | true
        'i' | nil | false
        nil | 's' | false
        'i' | 's' | true
      end

      with_them do
        it 'works as expected' do
          setting.identity = identity
          setting.secret = secret

          if valid
            expect(setting).to be_valid
          else
            expect(setting).not_to be_valid
          end
        end
      end
    end
  end

  describe '#authorization_header' do
    let_it_be_with_reload(:dependency_proxy_setting) { create(:dependency_proxy_group_setting) }

    subject { dependency_proxy_setting.authorization_header }

    context 'with identity and secret set' do
      let(:expected_headers) { { Authorization: 'Basic aTpz' } }

      before do
        dependency_proxy_setting.update!(identity: 'i', secret: 's')
      end

      it { is_expected.to eq(expected_headers) }
    end

    context 'with identity and secret not set' do
      before do
        dependency_proxy_setting.update!(identity: nil, secret: nil)
      end

      it { is_expected.to eq({}) }
    end
  end
end
