# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InProductMarketingEmailsWorker, '#perform' do
  context 'when the experiment is inactive' do
    before do
      stub_experiment(in_product_marketing_emails: false)
    end

    it 'does not execute the in product marketing emails service' do
      expect(Namespaces::InProductMarketingEmailsService).not_to receive(:send_for_all_tracks_and_intervals)

      subject.perform
    end
  end

  context 'when the experiment is active' do
    before do
      stub_experiment(in_product_marketing_emails: true)
    end

    it 'calls the send_for_all_tracks_and_intervals method on the in product marketing emails service' do
      expect(Namespaces::InProductMarketingEmailsService).to receive(:send_for_all_tracks_and_intervals)

      subject.perform
    end
  end
end
