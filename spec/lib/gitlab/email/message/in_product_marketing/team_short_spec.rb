# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::TeamShort do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  let(:series) { 0 }

  subject(:message) { described_class.new(group: group, user: user, series: series) }

  describe 'public methods' do
    it 'returns value for series', :aggregate_failures do
      expect(message.subject_line).to eq 'Team up in GitLab for greater efficiency'
      expect(message.tagline).to be_nil
      expect(message.title).to eq 'Turn coworkers into collaborators'
      expect(message.subtitle).to eq 'Invite your team today to build better code (and processes) together'
      expect(message.body_line1).to be_empty
      expect(message.body_line2).to be_empty
      expect(message.cta_text).to eq 'Invite your colleagues today'
      expect(message.logo_path).to eq 'mailers/in_product_marketing/team-0.png'
    end

    describe '#progress' do
      subject { message.progress }

      before do
        allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
      end

      context 'on gitlab.com' do
        let(:is_gitlab_com) { true }

        it { is_expected.to include('This is email 1 of 4 in the Team series') }
      end

      context 'not on gitlab.com' do
        let(:is_gitlab_com) { false }

        it { is_expected.to include('This is email 1 of 4 in the Team series', Gitlab::Routing.url_helpers.profile_notifications_url) }
      end
    end
  end
end
