# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::Verify do
  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  subject(:message) { described_class.new(group: group, user: user, series: series)}

  describe "public methods" do
    context 'with series 0' do
      let(:series) { 0 }

      it 'returns value for series', :aggregate_failures do
        expect(message.subject_line).to be_present
        expect(message.tagline).to be_present
        expect(message.title).to be_present
        expect(message.subtitle).to be_present
        expect(message.body_line1).to be_present
        expect(message.body_line2).to be_nil
        expect(message.cta_text).to be_present
      end
    end

    context 'with series 1' do
      let(:series) { 1 }

      it 'returns value for series', :aggregate_failures do
        expect(message.subject_line).to be_present
        expect(message.tagline).to be_present
        expect(message.title).to be_present
        expect(message.subtitle).to be_present
        expect(message.body_line1).to be_present
        expect(message.body_line2).to be_present
        expect(message.cta_text).to be_present
      end
    end

    context 'with series 2' do
      let(:series) { 2 }

      it 'returns value for series', :aggregate_failures do
        expect(message.subject_line).to be_present
        expect(message.tagline).to be_present
        expect(message.title).to be_present
        expect(message.subtitle).to be_present
        expect(message.body_line1).to be_present
        expect(message.body_line2).to be_nil
        expect(message.cta_text).to be_present
      end
    end
  end
end
