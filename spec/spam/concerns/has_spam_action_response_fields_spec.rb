# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::Concerns::HasSpamActionResponseFields do
  subject do
    klazz = Class.new
    klazz.include described_class
    klazz.new
  end

  describe '#with_spam_action_response_fields' do
    let(:spam_log) { double(:spam_log, id: 1) }
    let(:spammable) { double(:spammable, spam?: true, render_recaptcha?: true, spam_log: spam_log) }
    let(:recaptcha_site_key) { 'abc123' }

    before do
      allow(Gitlab::CurrentSettings).to receive(:recaptcha_site_key) { recaptcha_site_key }
    end

    it 'merges in spam action fields from spammable' do
      expect(subject.spam_action_response_fields(spammable))
        .to eq({
                 spam: true,
                 needs_captcha_response: true,
                 spam_log_id: 1,
                 captcha_site_key: recaptcha_site_key
               })
    end
  end
end
