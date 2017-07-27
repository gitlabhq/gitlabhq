require 'spec_helper'

describe Burndown do
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
      weight: 2,
      project_id: project.id
    }
  end

  before do
    project.add_master(user)
    build_sample
  end

  after do
    Timecop.return
  end

  subject { described_class.new(milestone).to_json }

  it "generates an array with date, issue count and weight" do
    expect(subject).to eq([
      ["2017-03-01", 33, 66],
      ["2017-03-02", 35, 70],
      ["2017-03-03", 28, 56],
      ["2017-03-04", 32, 64],
      ["2017-03-05", 21, 42]
    ].to_json)
  end

  it "returns empty array if milestone start date is nil" do
    milestone.update(start_date: nil)

    expect(subject).to eq([].to_json)
  end

  it "returns empty array if milestone due date is nil" do
    milestone.update(due_date: nil)

    expect(subject).to eq([].to_json)
  end

  it "it counts until today if milestone due date > Date.today" do
    Timecop.travel(milestone.due_date - 1.day)

    expect(JSON.parse(subject).last[0]).to eq(Time.now.strftime("%Y-%m-%d"))
  end

  it "sets attribute accurate to true" do
    burndown = described_class.new(milestone)

    expect(burndown).to be_accurate
  end

  context "when all closed and reopened issues does not have closed_at" do
    before do
      milestone.issues.update_all(closed_at: nil)
    end

    it "considers closed_at as milestone start date" do
      expect(subject).to eq([
        ["2017-03-01", 15, 30],
        ["2017-03-02", 27, 54],
        ["2017-03-03", 27, 54],
        ["2017-03-04", 27, 54],
        ["2017-03-05", 27, 54]
      ].to_json)
    end

    it "sets attribute empty to true" do
      burndown = described_class.new(milestone)

      expect(burndown).to be_empty
    end
  end

  context "when one or more closed or reopened issues does not have closed_at" do
    before do
      milestone.issues.closed.first.update(closed_at: nil)
    end

    it "sets attribute accurate to false" do
      burndown = described_class.new(milestone)

      expect(burndown).not_to be_accurate
    end
  end

  # Creates, closes and reopens issues only for odd days numbers
  def build_sample
    milestone.start_date.upto(milestone.due_date) do |date|
      day = date.day
      next if day.even?

      count = day * 4
      Timecop.travel(date)

      # Create issues
      issues = create_list(:issue, count, issue_params)

      # Close issues
      closed = issues.slice(0..count / 2)
      closed.each(&:close)

      # Reopen issues
      closed.slice(0..count / 4).each(&:reopen)
    end

    Timecop.travel(due_date)
  end
end
