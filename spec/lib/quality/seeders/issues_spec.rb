# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Quality::Seeders::Issues do
  let(:project) { create(:project) }

  subject { described_class.new(project: project) }

  describe '#seed' do
    it 'seeds issues' do
      issues_created = subject.seed(backfill_weeks: 1, average_issues_per_week: 1)

      expect(issues_created).to be_between(0, 2)
      expect(project.issues.count).to eq(issues_created)
    end
  end
end
