# frozen_string_literal: true

RSpec::Matchers.define :gitaly_request_with_path do |storage_name, relative_path|
  match do |actual|
    repository = actual.repository

    repository.storage_name == storage_name &&
      repository.relative_path == relative_path
  end

  failure_message do |actual|
    repository = actual.repository
    "expected gitaly request with storage_name=#{storage_name.inspect} and " \
      "relative_path=#{relative_path.inspect}, but got " \
      "storage_name=#{repository.storage_name.inspect} and " \
      "relative_path=#{repository.relative_path.inspect}"
  end
end

RSpec::Matchers.define :gitaly_request_with_params do |params|
  match do |actual|
    params.reduce(true) { |r, (key, val)| r && actual[key.to_s] == val }
  end

  failure_message do |actual|
    mismatches = params.reject { |key, val| actual[key.to_s] == val }
    "expected gitaly request to include params #{params.inspect}, but mismatches: " \
      "#{mismatches.to_h { |key, val| [key, { expected: val, actual: actual[key.to_s] }] }.inspect}"
  end
end
