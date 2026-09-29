# frozen_string_literal: true

module StubIframeProviders
  def stub_iframe_providers(config)
    providers = config.map do |id, entry|
      Gitlab::Markdown::IframeProviders::Provider.from_config(id, entry)
    end

    allow(Gitlab::Markdown::IframeProviders).to receive(:known_providers).and_return(providers)
  end
end
