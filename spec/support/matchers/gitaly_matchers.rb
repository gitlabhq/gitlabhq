RSpec::Matchers.define :post_receive_request_with_repo_path do |path|
  match { |actual| actual.repository.path == path }
end
