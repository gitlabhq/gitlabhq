# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InProductMarketingEmailsWorker, '#perform', unless: Gitlab.ee? do
  # Running this in EE would call the overridden method, which can't be tested in CE.
  # The EE code is covered in a separate EE spec.

  context 'when the in_product_marketing_emails_enabled setting is disabled' do
    before do
      stub_application_setting(in_product_marketing_emails_enabled: false)
    end

    it 'does not execute the email service' do
      expect(Namespaces::InProductMarketingEmailsService).not_to receive(:send_for_all_tracks_and_intervals)

      subject.perform
    end
  end

  context 'when the in_product_marketing_emails_enabled setting is enabled' do
    before do
      stub_application_setting(in_product_marketing_emails_enabled: true)
    end

    it 'executes the email service' do
      expect(Namespaces::InProductMarketingEmailsService).to receive(:send_for_all_tracks_and_intervals)

      subject.perform
    end
  end
end
