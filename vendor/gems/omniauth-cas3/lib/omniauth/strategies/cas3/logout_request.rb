module OmniAuth
  module Strategies
    class CAS3
      class LogoutRequest
        def initialize(strategy, request)
          @strategy, @request = strategy, request
        end

        def call(options = {})
          @options = options

          begin
            result = single_sign_out_callback.call(*logout_request)
          rescue StandardError => err
            return @strategy.fail! :logout_request, err
          else
            result = [200,{},'OK'] if result == true || result.nil?
          ensure
            return unless result

            # TODO: Why does ActionPack::Response return [status,headers,body]
            # when Rack::Response#new wants [body,status,headers]? Additionally,
            # why does Rack::Response differ in argument order from the usual
            # Rack-like [status,headers,body] array?
            return Rack::Response.new(result[2],result[0],result[1]).finish
          end
        end

      private

        def logout_request
          @logout_request ||= begin
            saml = parse_and_ensure_namespaces(@request.params['logoutRequest'])
            ns = saml.collect_namespaces
            name_id = saml.xpath('//saml:NameID', ns).text
            sess_idx = saml.xpath('//samlp:SessionIndex', ns).text
            inject_params(name_id:name_id, session_index:sess_idx)
            @request
          end
        end

        def parse_and_ensure_namespaces(logout_request_xml)
          doc = Nokogiri.parse(logout_request_xml)
          ns = doc.collect_namespaces
          if ns.include?('xmlns:samlp') && ns.include?('xmlns:saml')
            doc
          else
            add_namespaces(doc)
          end
        end

        def add_namespaces(logout_request_doc)
          root = logout_request_doc.root
          root.add_namespace('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol')
          root.add_namespace('saml', 'urn:oasis:names:tc:SAML:2.0:assertion\\')

          # In order to add namespaces properly we need to re-parse the document
          Nokogiri.parse(logout_request_doc.to_s)
        end

        def inject_params(new_params)
          new_params.each do |key, val|
            @request.update_param(key, val)
          end
        end

        def single_sign_out_callback
          @options[:on_single_sign_out]
        end
      end
    end
  end
end
