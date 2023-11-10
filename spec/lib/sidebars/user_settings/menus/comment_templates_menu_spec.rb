# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::CommentTemplatesMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/comment_templates',
    title: _('Comment Templates'),
    icon: 'comment-lines',
    active_routes: { controller: :comment_templates }

  describe '#render?' do
    subject { described_class.new(context) }

    let_it_be(:user) { build(:user) }

    context 'when comment templates are enabled' do
      context 'when user is logged in' do
        let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

        it 'does not render' do
          expect(subject.render?).to be true
        end
      end

      context 'when user is not logged in' do
        let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

        subject { described_class.new(context) }

        it 'does not render' do
          expect(subject.render?).to be false
        end
      end
    end
  end
end
