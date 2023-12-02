# frozen_string_literal: true

RSpec.shared_context 'change access checks context' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:user_access) { Gitlab::UserAccess.new(user, container: project) }
  let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
  let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }
  let(:ref) { 'refs/heads/master' }
  let(:changes) { { oldrev: oldrev, newrev: newrev, ref: ref } }
  let(:protocol) { 'ssh' }
  let(:timeout) { Gitlab::GitAccess::INTERNAL_TIMEOUT }
  let(:logger) { Gitlab::Checks::TimedLogger.new(timeout: timeout) }
  let(:change_access) do
    Gitlab::Checks::SingleChangeAccess.new(
      changes,
      project: project,
      user_access: user_access,
      protocol: protocol,
      logger: logger
    )
  end

  subject(:change_check) { described_class.new(change_access) }

  before do
    project.add_developer(user)
  end
end
