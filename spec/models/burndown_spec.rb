require 'spec_helper'

describe Burndown, models: true do
  let(:start_date) { "2017-03-01" }
  let(:due_date)   { "2017-03-05" }
  let(:milestone)  { create(:milestone, start_date: start_date, due_date: due_date) }
  let(:project)    { milestone.project }
  let(:user)       { create(:user) }

  let(:issue_params) do
    {
      title: FFaker::Lorem.sentence(6),
      description: FFaker::Lorem.sentence,
      state: 'opened',
      milestone: milestone,
      weight: 2
    }
  end

  before do
    project.add_master(user)
    build_sample
  end

  after do
    Timecop.return
  end

  subject { described_class.new(milestone).chart_data }

  it "generates an array with date, issue count and weight" do
    expect(subject).to eq([
      ["2017-03-01", 33, 66],
      ["2017-03-02", 35, 70],
      ["2017-03-03", 28, 56],
      ["2017-03-04", 32, 64],
      ["2017-03-05", 21, 42]
    ])
  end

  it "returns empty array if milestone start date is nil" do
    milestone.update(start_date: nil)

    expect(subject).to eq([])
  end

  it "returns empty array if milestone due date is nil" do
    milestone.update(due_date: nil)

    expect(subject).to eq([])
  end

  # Creates, closes and reopens issues only for odd days numbers
  def build_sample
    milestone.start_date.upto(milestone.due_date) do |date|
      day = date.day
      next if day.even?

      count =  day * 4
      issues = []
      Timecop.travel(date)

      # Create issues
      count.times { issues << Issues::CreateService.new(project, user, issue_params).execute }

      # Close issues
      closed = issues.slice(0..count / 2)
      closed.each { |i| Issues::CloseService.new(project, user, {}).execute(i) }

      # Reopen issues
      closed.slice(0..count / 4).each { |i| i.reopen }
    end

    Timecop.travel(due_date)
  end
end
