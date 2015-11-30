Service.available_services_names.each do |service|
  shared_context service do
    let(:dashed_service) { service.dasherize }
    let(:service_method) { "#{service}_service".to_sym }
    let(:service_klass) { "#{service}_service".classify.constantize }
    let(:service_fields) { service_klass.new.fields }
    let(:service_attrs_list) do
      attrs = []
      service_fields.each do |field|
        if field[:type] == 'fieldset'
          field[:fields].each do |subfield|
            attrs << subfield[:name].to_sym
          end
        else
          attrs << field[:name].to_sym
        end
      end
      attrs
    end
    let(:service_attrs_list_without_passwords) do
      attrs = []
      service_fields.each do |field|
        if field[:type] == 'fieldset'
          field[:fields].each do |subfield|
            if subfield[:type] != 'password'
              attrs << subfield[:name].to_sym
            end
          end
        elsif field[:type] != 'password'
          attrs << field[:name].to_sym
        end
      end
      attrs
    end
    let(:service_attrs) do
      service_attrs_list.inject({}) do |hash, k|
        if k =~ /^(token*|.*_token|.*_key)/
          hash.merge!(k => 'secrettoken')
        elsif k =~ /^(.*_url|url|webhook)/
          hash.merge!(k => "http://example.com")
        elsif service == 'irker' && k == :recipients
          hash.merge!(k => 'irc://irc.network.net:666/#channel')
        elsif service == 'composer' && k == :package_mode
          hash.merge!(k => 'default')
        elsif service == 'composer' && k == :package_type
          hash.merge!(k => 'library')
        else
          hash.merge!(k => "someword")
        end
      end
    end
  end
end
