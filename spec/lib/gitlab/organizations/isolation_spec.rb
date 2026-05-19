# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Organizations::Isolation, feature_category: :organization do
  describe '.enabled?' do
    subject(:enabled?) { described_class.enabled? }

    let_it_be(:organization) { create(:organization) }

    context 'when data_isolation feature flag is disabled' do
      before do
        stub_feature_flags(data_isolation: false)
      end

      it { is_expected.to be false }
    end

    context 'when data_isolation feature flag is enabled' do
      before do
        stub_feature_flags(data_isolation: true)
      end

      context 'when Current.organization is not assigned' do
        it { is_expected.to be false }
      end

      context 'when Current.organization is assigned' do
        context 'when Current.organization is nil' do
          before do
            stub_current_organization(nil)
          end

          it { is_expected.to be false }
        end

        context 'when Current.organization is not isolated' do
          before do
            stub_current_organization(organization)
            allow(organization).to receive(:isolated?).and_return(false)
          end

          it { is_expected.to be false }
        end

        context 'when Current.organization is isolated' do
          before do
            stub_current_organization(organization)
            allow(organization).to receive(:isolated?).and_return(true)
          end

          it { is_expected.to be true }
        end

        it 'does not deadlock on recursive calls' do
          org = create(:organization)
          Current.organization = org

          expect { Project.find_by(id: 1) }.not_to raise_error
        end
      end
    end
  end
end
