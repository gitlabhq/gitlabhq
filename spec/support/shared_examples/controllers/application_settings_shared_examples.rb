# frozen_string_literal: true

RSpec.shared_examples 'renders correct panels' do
  it 'renders correct action on error' do
    expect_next_instance_of(ApplicationSettings::UpdateService) do |service|
      allow(service).to receive(:execute).and_return(false)
    end

    patch action, params: { application_setting: { unused_param: true } }

    expect(subject).to render_template(action)
  end

  it 'redirects to same panel on success' do
    expect_next_instance_of(ApplicationSettings::UpdateService) do |service|
      allow(service).to receive(:execute).and_return(true)
    end

    referer_path = public_send("#{action}_admin_application_settings_path")
    request.env["HTTP_REFERER"] = referer_path

    patch action, params: { application_setting: { unused_param: true } }

    expect(subject).to redirect_to(referer_path)
  end
end
