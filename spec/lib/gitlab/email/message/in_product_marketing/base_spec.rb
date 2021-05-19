# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::Base do
  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  let(:series) { 0 }
  let(:test_class) { Gitlab::Email::Message::InProductMarketing::Create }

  describe 'initialize' do
    subject { test_class.new(group: group, user: user, series: series) }

    context 'when series does not exist' do
      let(:series) { 3 }

      it 'raises error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when series exists' do
      let(:series) { 0 }

      it 'does not raise error' do
        expect { subject }.not_to raise_error(ArgumentError)
      end
    end
  end

  describe '#logo_path' do
    subject { test_class.new(group: group, user: user, series: series).logo_path }

    it { is_expected.to eq('mailers/in_product_marketing/create-0.png') }
  end

  describe '#unsubscribe' do
    subject { test_class.new(group: group, user: user, series: series).unsubscribe }

    before do
      allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
    end

    context 'on gitlab.com' do
      let(:is_gitlab_com) { true }

      it { is_expected.to include('%tag_unsubscribe_url%') }
    end

    context 'not on gitlab.com' do
      let(:is_gitlab_com) { false }

      it { is_expected.to include(Gitlab::Routing.url_helpers.profile_notifications_url) }
    end
  end

  describe '#cta_link' do
    subject(:cta_link) { test_class.new(group: group, user: user, series: series).cta_link }

    it 'renders link' do
      expect(CGI.unescapeHTML(cta_link)).to include(Gitlab::Routing.url_helpers.group_email_campaigns_url(group, track: :create, series: series))
    end
  end

  describe '#progress' do
    subject { test_class.new(group: group, user: user, series: series).progress }

    before do
      allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
    end

    context 'on gitlab.com' do
      let(:is_gitlab_com) { true }

      it { is_expected.to include('This is email 1 of 3 in the Create series') }
    end

    context 'not on gitlab.com' do
      let(:is_gitlab_com) { false }

      it { is_expected.to include('This is email 1 of 3 in the Create series', Gitlab::Routing.url_helpers.profile_notifications_url) }
    end
  end
end
