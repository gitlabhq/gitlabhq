Service.available_services_names.each do |service|
  shared_context service do
    let(:dashed_service) { service.dasherize }
    let(:service_method) { "#{service}_service".to_sym }
    let(:service_klass) { "#{service}_service".classify.constantize }
    let(:service_attrs_list) { service_klass.new.fields.inject([]) {|arr, hash| arr << hash[:name].to_sym } }
    let(:service_attrs) do
      service_attrs_list.inject({}) do |hash, k|
        if k =~ /^(token*|.*_token|.*_key)/
          hash.merge!(k => 'secrettoken')
        elsif k =~ /^(.*_url|url|webhook)/
          hash.merge!(k => "http://example.com")
        elsif service == 'irker' && k == :recipients
          hash.merge!(k => 'irc://irc.network.net:666/#channel')
        else
          hash.merge!(k => "someword")
        end
      end
    end
  end
end
