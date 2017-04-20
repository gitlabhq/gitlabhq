RSpec::Matchers.define :gitaly_request_with_repo_path do |path|
  match { |actual| actual.repository.path == path }
end
