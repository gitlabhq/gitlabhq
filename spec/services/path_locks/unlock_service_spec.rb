require 'spec_helper'

describe PathLocks::UnlockService, services: true do
  let(:path_lock)    { create :path_lock }
  let(:current_user) { path_lock.user }
  let(:project)      { path_lock.project }
  let(:path)         { path_lock.path }

  it 'unlocks path' do
    allow_any_instance_of(described_class).to receive(:can?).and_return(true)
    described_class.new(project, current_user).execute(path_lock)

    expect(project.path_locks.find_by(path: path)).to be_falsey
  end

  it 'raises exception if user has no permissions' do
    user = create :user

    expect do
      described_class.new(project, user).execute(path_lock)
    end.to raise_exception(PathLocks::UnlockService::AccessDenied)
  end

end
