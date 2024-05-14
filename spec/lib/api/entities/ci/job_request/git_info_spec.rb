# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobRequest::GitInfo, feature_category: :continuous_integration do
  let(:job) { build(:ci_build) }
  let(:git_info) { Ci::BuildRunnerPresenter.new(job) }
  let(:entity) { described_class.new(git_info) }

  describe '#as_json' do
    subject(:as_json) { entity.as_json }

    it 'exposes correct attributes' do
      expect(as_json.keys).to contain_exactly(
        :repo_url, :ref, :sha, :before_sha,
        :ref_type, :refspecs, :depth, :repo_object_format
      )
    end
  end
end
