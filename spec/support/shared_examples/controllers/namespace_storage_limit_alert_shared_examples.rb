# frozen_string_literal: true

RSpec.shared_examples 'namespace storage limit alert' do
  let(:alert_level) { :info }

  before do
    allow_next_instance_of(Namespaces::CheckStorageSizeService, namespace, user) do |check_storage_size_service|
      expect(check_storage_size_service).to receive(:execute).and_return(
        ServiceResponse.success(
          payload: {
            alert_level: alert_level,
            usage_message: "Usage",
            explanation_message: "Explanation",
            root_namespace: namespace
          }
        )
      )
    end

    allow(controller).to receive(:current_user).and_return(user)
  end

  render_views

  it 'does render' do
    subject

    expect(response.body).to match(/Explanation/)
    expect(response.body).to have_css('.js-namespace-storage-alert-dismiss')
  end

  context 'when alert_level is error' do
    let(:alert_level) { :error }

    it 'does not render a dismiss button' do
      subject

      expect(response.body).not_to have_css('.js-namespace-storage-alert-dismiss')
    end
  end

  context 'when cookie is set' do
    before do
      cookies["hide_storage_limit_alert_#{namespace.id}_info"] = 'true'
    end

    it 'does not render alert' do
      subject

      expect(response.body).not_to match(/Explanation/)
    end
  end
end
