# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectExportJob, type: :model do
  let(:project) { create(:project) }
  let!(:job1) { create(:project_export_job, project: project, status: 0) }
  let!(:job2) { create(:project_export_job, project: project, status: 2) }

  describe 'associations' do
    it { expect(job1).to belong_to(:project) }
  end

  describe 'validations' do
    it { expect(job1).to validate_presence_of(:project) }
    it { expect(job1).to validate_presence_of(:jid) }
    it { expect(job1).to validate_presence_of(:status) }
  end
end
