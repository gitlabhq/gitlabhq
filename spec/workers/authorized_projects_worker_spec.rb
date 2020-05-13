# frozen_string_literal: true

require 'spec_helper'

describe AuthorizedProjectsWorker do
  it_behaves_like "refreshes user's project authorizations"
end
