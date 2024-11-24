# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module OAuth
      module Authorization
        module Code
          if Doorkeeper::OAuth::Authorization::Code.method_defined?(:issue_token!)
            def issue_token!
              super.tap do |access_grant|
                create_openid_request(access_grant) if pre_auth.nonce.present?
              end
            end

            alias issue_token issue_token!
          else
            # FIXME: drop this after dropping support of Doorkeeper < 5.4
            def issue_token
              super.tap do |access_grant|
                create_openid_request(access_grant) if pre_auth.nonce.present?
              end
            end
          end

          private

          def create_openid_request(access_grant)
            ::Doorkeeper::OpenidConnect::Request.create!(
              access_grant: access_grant,
              nonce: pre_auth.nonce
            )
          end
        end
      end
    end
  end

  OAuth::Authorization::Code.prepend OpenidConnect::OAuth::Authorization::Code
end
