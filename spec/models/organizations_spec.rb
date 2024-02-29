# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations, feature_category: :cell do
  describe 'constants' do
    it { expect(described_class::ORGANIZATION_HTTP_HEADER).to eq('HTTP_GITLAB_ORGANIZATION_ID') }
  end
end
