# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::ContainerRegistryAuthenticationService, feature_category: :container_registry do
  include AdminModeHelper

  it_behaves_like 'a container registry auth service'
end
