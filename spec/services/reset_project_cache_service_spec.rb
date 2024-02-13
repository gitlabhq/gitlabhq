# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResetProjectCacheService, feature_category: :continuous_integration do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user).execute }

  context 'when project cache_index is nil' do
    before do
      project.jobs_cache_index = nil
    end

    it 'sets project cache_index to one' do
      expect { subject }.to change { project.reload.jobs_cache_index }.from(nil).to(1)
    end
  end

  context 'when project cache_index is a numeric value' do
    before do
      project.update!(jobs_cache_index: 1)
    end

    it 'increments project cache index' do
      expect { subject }.to change { project.reload.jobs_cache_index }.by(1)
    end
  end
end
