# frozen_string_literal: true

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
