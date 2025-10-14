# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::WikiPushService, :services, feature_category: :wiki do
  include_examples 'Git::WikiPushService', :project_wiki
end
