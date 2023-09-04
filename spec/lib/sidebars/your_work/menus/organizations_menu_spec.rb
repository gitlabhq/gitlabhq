# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::OrganizationsMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when `ui_for_organizations` feature flag is enabled' do
      context 'when `current_user` is available' do
        before do
          stub_feature_flags(ui_for_organizations: [user])
        end

        it 'returns true' do
          expect(subject.render?).to eq true
        end
      end

      context 'when `current_user` is not available' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end
    end

    context 'when `ui_for_organizations` feature flag is disabled' do
      before do
        stub_feature_flags(ui_for_organizations: false)
      end

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end
end
