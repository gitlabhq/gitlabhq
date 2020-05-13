# frozen_string_literal: true

require 'spec_helper'

describe WikiPages::UpdateService do
  it_behaves_like 'WikiPages::UpdateService#execute', :project
end
