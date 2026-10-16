# frozen_string_literal: true

module StubIframeProviders
  def stub_iframe_providers(config)
    providers = config.map do |id, entry|
      Banzai::IframeProviders::Provider.from_config(id, entry)
    end

    allow(Banzai::IframeProviders).to receive(:known_providers).and_return(providers)
  end
end
