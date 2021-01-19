# frozen_string_literal: true

require 'spec_helper'

# This is a compatibility class to avoid calling a non-existent
# class from sidekiq during deployment.
#
# We're deploying the name of the referenced class in 13.9. Nevertheless,
# we cannot remove the class entirely because there can be jobs
# referencing it. We still need this specs to ensure that the old
# class still has the old behavior.
#
# We can get rid of this class in 13.10
# https://gitlab.com/gitlab-org/gitlab/-/issues/297580
#
RSpec.describe Projects::HousekeepingService do
  it_behaves_like 'housekeeps repository' do
    let_it_be(:resource) { create(:project, :repository) }
  end
end
