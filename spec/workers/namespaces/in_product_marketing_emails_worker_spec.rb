# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InProductMarketingEmailsWorker, '#perform' do
  using RSpec::Parameterized::TableSyntax

  RSpec.shared_examples 'in-product marketing email' do
    before do
      stub_application_setting(in_product_marketing_emails_enabled: in_product_marketing_emails_enabled)
      stub_experiment(in_product_marketing_emails: experiment_active)
      allow(::Gitlab).to receive(:com?).and_return(is_gitlab_com)
    end

    it 'executes the email service service' do
      expect(Namespaces::InProductMarketingEmailsService).to receive(:send_for_all_tracks_and_intervals).exactly(executes_service).times

      subject.perform
    end
  end

  context 'not on gitlab.com' do
    let(:is_gitlab_com) { false }

    where(:in_product_marketing_emails_enabled, :experiment_active, :executes_service) do
      true     | true     | 1
      true     | false    | 1
      false    | false    | 0
      false    | true     | 0
    end

    with_them do
      include_examples 'in-product marketing email'
    end
  end

  context 'on gitlab.com' do
    let(:is_gitlab_com) { true }

    where(:in_product_marketing_emails_enabled, :experiment_active, :executes_service) do
      true     | true     | 1
      true     | false    | 0
      false    | false    | 0
      false    | true     | 0
    end

    with_them do
      include_examples 'in-product marketing email'
    end
  end
end
