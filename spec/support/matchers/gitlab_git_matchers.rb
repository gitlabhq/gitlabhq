# frozen_string_literal: true

RSpec::Matchers.define :gitlab_git_repository_with do |values|
  match do |actual|
    actual.is_a?(Gitlab::Git::Repository) &&
      values.all? { |k, v| actual.send(k) == v }
  end
end
