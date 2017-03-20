require 'spec_helper'

describe Burndown, models: true do
  let(:range) { 10 }
  let(:milestone) { create(:milestone, start_date: range.days.ago, due_date: Date.today) }
  let(:project) { milestone.project }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    @closed_by_date = {}

    range.times do |i|
      date = i.days.ago
      @closed_by_date[date] ||= []

      issue_params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentence,
        state: 'closed',
        milestone: milestone,
        closed_at: date,
        weight: rand(9)
      }

      rand(1..4).times do |i|
        @closed_by_date[date] << Issues::CreateService.new(project, user, issue_params).execute
      end
    end
  end

  subject { described_class.new(milestone).closed_issues }

  it "groups count and weight by closed_at" do
    sample =
      Hash[
        @closed_by_date.sort.map do |k, v|
          [k.strftime('%d %b'), [v.count, v.map { |issues| issues.weight }.sum]]
        end
      ]

    expect(sample).to eq(subject)
  end
end
