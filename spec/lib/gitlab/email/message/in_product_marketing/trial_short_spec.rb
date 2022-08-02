# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::TrialShort do
  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  let(:series) { 0 }

  subject(:message) { described_class.new(group: group, user: user, series: series) }

  describe 'public methods' do
    it 'returns value for series', :aggregate_failures do
      expect(message.subject_line).to eq 'Be a DevOps hero'
      expect(message.tagline).to be_nil
      expect(message.title).to eq 'Expand your DevOps journey with a free GitLab trial'
      expect(message.subtitle).to eq 'Start your trial today to experience single application success and discover all the features of GitLab Ultimate for free!'
      expect(message.body_line1).to be_empty
      expect(message.body_line2).to be_empty
      expect(message.cta_text).to eq 'Start a trial'
      expect(message.logo_path).to eq 'mailers/in_product_marketing/trial-0.png'
    end

    describe '#progress' do
      subject { message.progress }

      before do
        allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
      end

      context 'on gitlab.com' do
        let(:is_gitlab_com) { true }

        it { is_expected.to eq('This is email 1 of 4 in the Trial series.') }
      end

      context 'not on gitlab.com' do
        let(:is_gitlab_com) { false }

        it { is_expected.to include('This is email 1 of 4 in the Trial series', Gitlab::Routing.url_helpers.profile_notifications_url) }
      end
    end
  end
end
