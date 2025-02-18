# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:seed:group_seed rake task', :silence_stdout, feature_category: :groups_and_projects do
  let(:username) { 'group_seed' }
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, username: username, organizations: [organization]) }
  let(:task_params) { [2, username, organization.path] }

  before do
    Rake.application.rake_require('tasks/gitlab/seed/group_seed')
  end

  subject { run_rake_task('gitlab:seed:group_seed', task_params) }

  it 'performs group seed successfully', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444373' do
    expect { subject }.not_to raise_error

    group = user.groups.first

    expect(user.groups.count).to be 3
    expect(group.projects.count).to be 2
    expect(group.members.count).to be 3
    expect(group.milestones.count).to be 2
  end

  context 'when user is not a member of the organization' do
    let(:other_organization) { create(:organization) }
    let(:task_params) { [2, username, other_organization.path] }

    it 'raises error' do
      expect { subject }.to raise_error('User must belong to the organization')
    end
  end
end
