# frozen_string_literal: true

# This is a really hacky way of injecting feature flags by forcing the
# below request_kwargs method to execute before the actual one in the
# Gitaly client. I don't really like this, but it should work well for
# now and avoids needing to change how repositories are created throughout
# the tests.
module GitalyMvcc
  module RequestKwargsPatch
    def request_kwargs(...)
      super.tap do |kwargs|
        kwargs[:metadata]['gitaly-feature-new-repo-mvcc-backend'] = 'true'
      end
    end
  end
end

if GitalySetup.mvcc_repositories?
  Gitlab::GitalyClient.singleton_class.prepend(GitalyMvcc::RequestKwargsPatch)

  RSpec.configure do |config|
    config.before(:each, :skip_gitaly_mvcc) do
      skip 'Not supported with the MVCC reference backend. ' \
        'See https://gitlab.com/gitlab-org/gitaly/-/work_items/7369.'
    end
  end
end
