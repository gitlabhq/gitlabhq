require 'nokogiri'
require 'net/http'
require 'net/https'

module OmniAuth
  module Strategies
    class Crowd
      class CrowdValidator
        AUTHENTICATION_REQUEST_BODY = "<password><value>%s</value></password>"
        def initialize(configuration, username, password, client_ip, tokens)
          @configuration, @username, @password, @client_ip, @tokens = configuration, username, password, client_ip, tokens
          @authentiction_uri = URI.parse(@configuration.authentication_url(@username))
          @session_uri       = URI.parse(@configuration.session_url) if @configuration.use_sessions
        end

        def user_info
          user_info_hash = retrieve_user_info!

          if user_info_hash && @configuration.include_users_groups?
            user_info_hash = add_user_groups!(user_info_hash)
          else
            user_info_hash
          end

          if user_info_hash && @configuration.use_sessions?
            user_info_hash = set_session!(user_info_hash)
          end

          user_info_hash
        end

        private
        def set_session!(user_info_hash)

          response = nil

          if user_info_hash["sso_token"]
            response = make_session_request(user_info_hash["sso_token"])
          else
            response = make_session_request(nil)
          end

          if response.kind_of?(Net::HTTPSuccess) && response.body
            doc = Nokogiri::XML(response.body)
            user_info_hash["sso_token"] = doc.xpath('//token/text()').to_s
          else
            OmniAuth.logger.send(:warn, "(crowd) [set_session!] response code: #{response.code.to_s}")
            OmniAuth.logger.send(:warn, "(crowd) [set_session!] response body: #{response.body}")
          end

          user_info_hash
        end

        def add_user_groups!(user_info_hash)
          response = make_user_group_request(user_info_hash['user'])
          unless response.code.to_i != 200 || response.body.nil? || response.body == ''
            doc = Nokogiri::XML(response.body)
            user_info_hash["groups"] = doc.xpath("//groups/group/@name").map(&:to_s)
          end
          user_info_hash
        end

        def retrieve_user_info!
          response = make_authorization_request

          unless response === nil
            unless response.code.to_i != 200 || response.body.nil? || response.body == ''

              doc = Nokogiri::XML(response.body)
              result = {
                "user" => doc.xpath("//user/@name").to_s,
                "name" => doc.xpath("//user/display-name/text()").to_s,
                "first_name" => doc.xpath("//user/first-name/text()").to_s,
                "last_name" => doc.xpath("//user/last-name/text()").to_s,
                "email" => doc.xpath("//user/email/text()").to_s
              }

              if doc.at_xpath("//token")
                result["sso_token"] = doc.xpath("//token/text()").to_s
              end

              result
              
            else
              OmniAuth.logger.send(:warn, "(crowd) [retrieve_user_info!] response code: #{response.code.to_s}")
              OmniAuth.logger.send(:warn, "(crowd) [retrieve_user_info!] response body: #{response.body}")
              nil
            end
          else
            OmniAuth.logger.send(:warn, "(crowd) [retrieve_user_info!] None of the session tokens were valid")
            nil
          end
        end

        def make_request(uri, body=nil)
          http_method = body.nil? ? Net::HTTP::Get : Net::HTTP::Post
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.port == 443 || uri.instance_of?(URI::HTTPS)
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && @configuration.disable_ssl_verification?
          http.start do |c|
            req = http_method.new(uri.query.nil? ? uri.path : "#{uri.path}?#{uri.query}")
            req.body = body if body
            req.basic_auth @configuration.crowd_application_name, @configuration.crowd_password
            if @configuration.content_type
              req.add_field 'Content-Type', @configuration.content_type
            end
            http.request(req)
          end
        end

        def make_user_group_request(username)
          make_request(URI.parse(@configuration.user_group_url(username)))
        end

        def make_authorization_request

          if @configuration.use_sessions? && @tokens.kind_of?(Array)
            make_session_retrieval_request
          else 
            make_request(@authentiction_uri, make_authentication_request_body(@password))
          end
        end

        def make_session_request(token)

          root = url = validation_factor = nil
          doc = Nokogiri::XML::Document.new

          if token === nil

            url = @session_uri
            root = doc.create_element('authentication-context')

            doc.root = root
            root.add_child(doc.create_element('username', @username))
            root.add_child(doc.create_element('password', @password))

          else
            url = URI.parse(@session_uri.to_s() + "/#{token}")
          end

          if @configuration.use_sessions? || @client_ip

            if root === nil
              root = doc.create_element('validation-factors')
              doc.root = root
            else
              root.add_child(doc.create_element('validation-factors'))
            end

            validation_factor = doc.create_element('validation-factor')
            validation_factor.add_child(doc.create_element('name', 'remote_address'))
            validation_factor.add_child(doc.create_element('value', @client_ip))
            
            doc.xpath('//validation-factors').first.add_child(validation_factor)
            
          end
          
          make_request(url, doc.to_s)
          
        end        

        # create the body using Nokogiri so proper encoding of passwords can be ensured
        def make_authentication_request_body(password)
          request_body = Nokogiri::XML(AUTHENTICATION_REQUEST_BODY)
          password_value = request_body.at_css "value"
          password_value.content = password
          return request_body.root.to_s # return the body without the xml header
        end

        def make_session_retrieval_request

          response = nil

          @tokens.any? { |token|
            response = make_request(URI.parse(@session_uri.to_s() + "/#{token}"))
            response.code.to_i == 200 && !response.body.nil? && response.body != ''
          }            

          response
          
        end
      end
    end
  end
end
