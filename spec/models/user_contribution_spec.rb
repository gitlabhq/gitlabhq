require "spec_helper"

describe UserContribution, models: true do
  describe '.calculate_for' do
    let(:contributor) { create(:user) }
    let(:project) { create(:project) }

    it 'writes all user contributions for a given date' do
      create(:event, :created,
             project: project,
             target: create(:issue, project: project, author: contributor),
             author: contributor,
             created_at: 1.day.ago)

      UserContribution.calculate_for(1.day.ago)

      expect(UserContribution.first.contributions).to eq(1)
    end
  end
end
