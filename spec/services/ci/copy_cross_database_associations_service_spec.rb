# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CopyCrossDatabaseAssociationsService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:old_build) { create(:ci_build, pipeline: pipeline) }
  let_it_be(:new_build) { create(:ci_build, pipeline: pipeline) }

  subject(:execute) { described_class.new.execute(old_build, new_build) }

  describe '#execute' do
    it 'returns a success response' do
      expect(execute).to be_success
    end
  end
end
