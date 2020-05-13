# frozen_string_literal: true

require 'spec_helper'

describe WikiPages::DestroyService do
  it_behaves_like 'WikiPages::DestroyService#execute', :project
end
