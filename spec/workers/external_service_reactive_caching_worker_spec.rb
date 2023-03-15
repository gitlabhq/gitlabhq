# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalServiceReactiveCachingWorker, feature_category: :shared do
  it_behaves_like 'reactive cacheable worker'
end
