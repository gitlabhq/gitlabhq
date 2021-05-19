# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DownloadableArtifactSerializer do
  let(:pipeline) { create(:ci_pipeline, :with_codequality_reports) }
  let(:user) { create(:user) }
  let(:serializer) { described_class.new(current_user: user).represent(pipeline) }

  describe '#as_json' do
    subject { serializer.as_json }

    it 'matches schema' do
      expect(subject).to match_schema('entities/downloadable_artifact')
    end
  end
end
