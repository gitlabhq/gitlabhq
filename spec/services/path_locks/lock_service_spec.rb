require 'spec_helper'

describe PathLocks::LockService, services: true do
  let(:current_user) { create(:user) }
  let(:project)      { create(:empty_project) }
  let(:path)         { 'app/models' }

  it 'locks path' do
    allow_any_instance_of(described_class).to receive(:can?).and_return(true)
    described_class.new(project, current_user).execute(path)

    expect(project.path_locks.find_by(path: path)).to be_truthy
  end

  it 'raises exception if user has no permissions' do
    expect do
      described_class.new(project, current_user).execute(path)
    end.to raise_exception(PathLocks::LockService::AccessDenied)
  end

end
