# frozen_string_literal: true

require 'google/rpc/status_pb'
require 'google/protobuf/well_known_types'

module DetailedErrorHelpers
  def new_detailed_error(error_code, error_message, details)
    status_error = Google::Rpc::Status.new(
      code: error_code,
      message: error_message,
      details: [Google::Protobuf::Any.pack(details)]
    )

    GRPC::BadStatus.new(
      error_code,
      error_message,
      { "grpc-status-details-bin" => Google::Rpc::Status.encode(status_error) })
  end
end
