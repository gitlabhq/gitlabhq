RSpec::Matchers.define :gitaly_request_with_repo_path do |path|
  match { |actual| actual.repository.path == path }
end

RSpec::Matchers.define :gitaly_request_with_params do |params|
  match do |actual|
    params.reduce(true) { |r, (key, val)| r && actual.send(key) == val }
  end
end
