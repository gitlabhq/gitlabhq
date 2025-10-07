# frozen_string_literal: true

require "grpc"

module Gitlab
  module Cells
    module TopologyService
      class MetadataClient < ::GRPC::ClientInterceptor
        def initialize(custom_metadata)
          @custom_metadata = custom_metadata
        end

        def request_response(metadata:, **)
          metadata.merge!(@custom_metadata) if @custom_metadata

          yield
        end
      end
    end
  end
end
