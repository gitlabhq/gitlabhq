# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::Team do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  subject(:message) { described_class.new(group: group, user: user, series: series) }

  describe "public methods" do
    where(series: [0, 1])

    with_them do
      it 'returns value for series', :aggregate_failures do
        expect(message.subject_line).to be_present
        expect(message.tagline).to be_present
        expect(message.title).to be_present
        expect(message.subtitle).to be_present
        expect(message.body_line1).to be_present
        expect(message.body_line2).to be_present
        expect(message.cta_text).to be_present
      end

      describe '#progress' do
        subject { message.progress }

        before do
          allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
        end

        context 'on gitlab.com' do
          let(:is_gitlab_com) { true }

          it { is_expected.to include("This is email #{series + 2} of 4 in the Team series") }
        end

        context 'not on gitlab.com' do
          let(:is_gitlab_com) { false }

          it { is_expected.to include("This is email #{series + 2} of 4 in the Team series", Gitlab::Routing.url_helpers.profile_notifications_url) }
        end
      end
    end

    context 'with series 2' do
      let(:series) { 2 }

      it 'returns value for series', :aggregate_failures do
        expect(message.subject_line).to be_present
        expect(message.tagline).to be_nil
        expect(message.title).to be_present
        expect(message.subtitle).to be_present
        expect(message.body_line1).to be_present
        expect(message.body_line2).to be_present
        expect(message.cta_text).to be_present
      end

      describe '#progress' do
        subject { message.progress }

        before do
          allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
        end

        context 'on gitlab.com' do
          let(:is_gitlab_com) { true }

          it { is_expected.to include('This is email 4 of 4 in the Team series') }
        end

        context 'not on gitlab.com' do
          let(:is_gitlab_com) { false }

          it { is_expected.to include('This is email 4 of 4 in the Team series', Gitlab::Routing.url_helpers.profile_notifications_url) }
        end
      end
    end
  end
end
