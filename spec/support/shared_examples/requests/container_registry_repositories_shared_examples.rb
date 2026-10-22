# frozen_string_literal: true

RSpec.shared_examples 'container registry app root with registry errors' do
  {
    Faraday::Error => 'data-connection-error',
    ContainerRegistry::Path::InvalidRegistryPathError => 'data-invalid-path-error'
  }.each do |error_class, attribute|
    context "when there is a #{error_class}" do
      before do
        allow(::ContainerRegistry::Client).to receive(:registry_info).and_raise(error_class, nil, nil)
      end

      it "sets #{attribute} on the app root" do
        app_root = Nokogiri::HTML(index_response.body).at_css('#js-container-registry')

        expect(app_root[attribute]).to eq('true')
      end
    end
  end
end
