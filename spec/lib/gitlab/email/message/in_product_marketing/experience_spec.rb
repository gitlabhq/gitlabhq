# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::Experience do
  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  subject(:message) { described_class.new(group: group, user: user, series: series)}

  describe 'public methods' do
    context 'with series 0' do
      let(:series) { 0 }

      it 'returns value for series', :aggregate_failures do
        expect(message.subject_line).to be_present
        expect(message.tagline).to be_nil
        expect(message.title).to be_present
        expect(message.subtitle).to be_present
        expect(message.body_line1).to be_present
        expect(message.body_line2).to be_present
        expect(message.cta_text).to be_nil
      end

      describe '#feedback_link' do
        let(:member_count) { 2 }
        let(:user_access) { GroupMember::DEVELOPER }
        let(:preferred_language) { 'en' }

        before do
          allow(message).to receive(:onboarding_progress).and_return(1)
          allow(group).to receive(:member_count).and_return(member_count)
          allow(group).to receive(:max_member_access_for_user).and_return(user_access)
          allow(user).to receive(:preferred_language).and_return(preferred_language)
        end

        subject do
          uri = URI.parse(message.feedback_link(1))
          Rack::Utils.parse_query(uri.query).with_indifferent_access[:show_invite_link]
        end

        it { is_expected.to eq('true') }

        context 'with only one member' do
          let(:member_count) { 1 }

          it { is_expected.to eq('false') }
        end

        context 'with less than developer access' do
          let(:user_access) { GroupMember::GUEST }

          it { is_expected.to eq('false') }
        end

        context 'with preferred language other than English' do
          let(:preferred_language) { 'nl' }

          it { is_expected.to eq('false') }
        end
      end
    end
  end
end
