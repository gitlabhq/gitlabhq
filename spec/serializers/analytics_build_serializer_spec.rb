# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AnalyticsBuildSerializer do
  let(:resource) { create(:ci_build) }

  subject { described_class.new.represent(resource) }

  context 'when there is a single object provided' do
    it 'contains important elements of analyticsBuild' do
      expect(subject)
        .to include(:name, :branch, :short_sha, :date, :total_time, :url, :author)
    end
  end
end
