# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    class Request < ::ActiveRecord::Base
      self.table_name = "#{table_name_prefix}oauth_openid_requests#{table_name_suffix}".to_sym

      validates :access_grant_id, :nonce, presence: true

      if Gem.loaded_specs['doorkeeper'].version >= Gem::Version.create('5.5.0')
        belongs_to :access_grant,
                   class_name: Doorkeeper.config.access_grant_class.to_s,
                   inverse_of: :openid_request
      else
        belongs_to :access_grant,
                   class_name: 'Doorkeeper::AccessGrant',
                   inverse_of: :openid_request
      end
    end
  end
end
