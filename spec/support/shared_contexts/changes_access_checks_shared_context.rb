# frozen_string_literal: true

RSpec.shared_context 'changes access checks context' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:user_access) { Gitlab::UserAccess.new(user, container: project) }
  let(:protocol) { 'ssh' }
  let(:timeout) { Gitlab::GitAccess::INTERNAL_TIMEOUT }
  let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
  let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }
  let(:ref) { 'refs/heads/master' }
  let(:changes) do
    [
      # Update of existing branch
      { oldrev: oldrev, newrev: newrev, ref: ref },
      # Creation of new branch
      { newrev: newrev, ref: 'refs/heads/something' },
      # Deletion of branch
      { oldrev: oldrev, ref: 'refs/heads/deleteme' }
    ]
  end

  let(:logger) { Gitlab::Checks::TimedLogger.new(timeout: timeout) }
  let(:changes_access) do
    Gitlab::Checks::ChangesAccess.new(
      changes,
      project: project,
      user_access: user_access,
      protocol: protocol,
      logger: logger
    )
  end

  subject { described_class.new(changes_access) }

  before do
    project.add_developer(user)
  end
end
