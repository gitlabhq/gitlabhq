# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StripAttribute, feature_category: :shared do
  let(:milestone) { create(:milestone) }

  describe ".strip_attributes!" do
    it { expect(Milestone).to respond_to(:strip_attributes!) }
    it { expect(Milestone.strip_attrs).to include(:title) }
    it { expect(Issue.strip_attrs).to include(:title) }
    it { expect(WorkItem.strip_attrs).to include(:title) }
    it { expect(Achievements::Achievement.strip_attrs).to include(:name, :description) }
    it { expect(User.strip_attrs).to include(:name) }
    it { expect(Ci::FreezePeriod.strip_attrs).to include(:freeze_start, :freeze_end) }
    it { expect(Ci::PipelineSchedule.strip_attrs).to include(:cron) }
    it { expect(CustomerRelations::Contact.strip_attrs).to include(:phone, :first_name, :last_name) }
    it { expect(CustomerRelations::Organization.strip_attrs).to include(:name) }
    it { expect(TimeTracking::TimelogCategory.strip_attrs).to include(:name) }
  end

  describe "#strip_attributes!" do
    before do
      milestone.title = '    8.3   '
      milestone.valid?
    end

    it { expect(milestone.title).to eq('8.3') }
  end
end
