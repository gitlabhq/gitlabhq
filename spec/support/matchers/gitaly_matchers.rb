# frozen_string_literal: true

RSpec::Matchers.define :gitaly_request_with_path do |storage_name, relative_path|
  match do |actual|
    repository = actual.repository

    repository.storage_name == storage_name &&
      repository.relative_path == relative_path
  end
end

RSpec::Matchers.define :gitaly_request_with_params do |params|
  match do |actual|
    params.reduce(true) { |r, (key, val)| r && actual[key.to_s] == val }
  end
end
