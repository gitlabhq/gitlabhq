require 'spec_helper'

describe Ci::CreateJobService, '#execute' do
  set(:project) { create(:project, :repository) }
  let(:user) { create(:admin) }
  let(:status) { build(:ci_build) }
  let(:service) { described_class.new(project, user) }

  it 'persists job object instantiated in the block' do
    expect(service.execute { status }).to be_persisted
  end

  it 'persists a job instance passed as an argument' do
    expect(service.execute(status)).to be_persisted
  end

  it 'ensures that a job has a stage assigned' do
    expect(service.execute(status).stage_id).to be_present
  end

  it 'does not raise error if status is invalid' do
    status.name = nil

    expect(service.execute(status)).not_to be_persisted
  end
end
