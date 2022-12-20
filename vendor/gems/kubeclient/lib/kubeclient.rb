require 'json'
require 'rest-client'

require 'kubeclient/aws_eks_credentials'
require 'kubeclient/common'
require 'kubeclient/config'
require 'kubeclient/entity_list'
require 'kubeclient/exec_credentials'
require 'kubeclient/gcp_auth_provider'
require 'kubeclient/http_error'
require 'kubeclient/missing_kind_compatibility'
require 'kubeclient/oidc_auth_provider'
require 'kubeclient/resource'
require 'kubeclient/resource_not_found_error'
require 'kubeclient/version'
require 'kubeclient/watch_stream'

module Kubeclient
  # Kubernetes Client
  class Client
    include ClientMixin
    def initialize(
      uri,
      version = 'v1',
      **options
    )
      initialize_client(
        uri,
        '/api',
        version,
        **options
      )
    end
  end
end
