# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::DestroyService, feature_category: :wiki do
  it_behaves_like 'WikiPages::DestroyService#execute', :project
end
