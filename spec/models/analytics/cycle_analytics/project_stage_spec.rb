# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalytics::ProjectStage do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end
end
