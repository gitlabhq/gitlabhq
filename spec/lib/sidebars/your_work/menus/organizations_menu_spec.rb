# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::OrganizationsMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject(:menu) { described_class.new(context) }

  describe '#render?' do
    context 'when `ui_for_organizations` feature flag is disabled' do
      before do
        stub_feature_flags(ui_for_organizations: false)
      end

      it 'returns false' do
        expect(menu.render?).to be false
      end
    end

    context 'when `ui_for_organizations` feature flag is enabled' do
      context 'when `current_user` is not available' do
        let(:user) { nil }

        it 'returns false' do
          expect(menu.render?).to be false
        end
      end

      context 'when `current_user` is available' do
        context 'on GitLab.com' do
          before do
            allow(Gitlab).to receive(:com?).and_return(true)
          end

          context 'when the user has an active non-default organization' do
            before do
              allow(user).to receive(:has_active_non_default_organization?).and_return(true)
            end

            it 'returns true' do
              expect(menu.render?).to be true
            end
          end

          context 'when the user does not have an active non-default organization' do
            before do
              allow(user).to receive(:has_active_non_default_organization?).and_return(false)
            end

            it 'returns false' do
              expect(menu.render?).to be false
            end
          end
        end

        context 'when not on GitLab.com' do
          before do
            allow(Gitlab).to receive(:com?).and_return(false)
            allow(user).to receive(:has_active_non_default_organization?).and_return(false)
          end

          it 'returns true regardless of organization membership' do
            expect(menu.render?).to be true
          end
        end
      end
    end
  end
end
