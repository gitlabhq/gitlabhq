# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::AdvanceStageWorker, feature_category: :importers do
  it_behaves_like Gitlab::Import::AdvanceStage, factory: :import_state
end
