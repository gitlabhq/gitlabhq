require 'spec_helper'

describe Projects::CreateService, '#execute', services: true do
  let(:user) { create :user }
  let(:opts) do
    {
      name: "GitLab",
      namespace: user.namespace
    }
  end

  it 'creates labels on Project creation if there are templates' do
    Label.create(title: "bug", template: true)
    project = create_project(user, opts)

    expect(project.labels).not_to be_empty
  end

  context 'user namespace' do
    it do
      project = create_project(user, opts)

      expect(project).to be_valid
      expect(project.owner).to eq(user)
      expect(project.team.masters).to include(user)
      expect(project.namespace).to eq(user.namespace)
    end
  end

  context 'group namespace' do
    let(:group) do
      create(:group).tap do |group|
        group.add_owner(user)
      end
    end

    before do
      user.refresh_authorized_projects # Ensure cache is warm
    end

    it do
      project = create_project(user, opts.merge!(namespace_id: group.id))

      expect(project).to be_valid
      expect(project.owner).to eq(group)
      expect(project.namespace).to eq(group)
      expect(user.authorized_projects).to include(project)
    end
  end

  context 'error handling' do
    it 'handles invalid options' do
      opts[:default_branch] = 'master'
      expect(create_project(user, opts)).to eq(nil)
    end
  end

  context 'wiki_enabled creates repository directory' do
    context 'wiki_enabled true creates wiki repository directory' do
      it do
        project = create_project(user, opts)
        path = ProjectWiki.new(project, user).send(:path_to_repo)

        expect(File.exist?(path)).to be_truthy
      end
    end

    context 'wiki_enabled false does not create wiki repository directory' do
      it do
        opts[:wiki_enabled] = false
        project = create_project(user, opts)
        path = ProjectWiki.new(project, user).send(:path_to_repo)

        expect(File.exist?(path)).to be_falsey
      end
    end
  end

  context 'builds_enabled global setting' do
    let(:project) { create_project(user, opts) }

    subject { project.builds_enabled? }

    context 'global builds_enabled false does not enable CI by default' do
      before do
        project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
      end

      it { is_expected.to be_falsey }
    end

    context 'global builds_enabled true does enable CI by default' do
      it { is_expected.to be_truthy }
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'assign repository_size_limit as Bytes' do
        project = create_project(admin_user, opts)

        expect(project.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        project = create_project(admin_user, opts)

        expect(project.repository_size_limit).to be_nil
      end
    end
  end

  context 'restricted visibility level' do
    before do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

      opts.merge!(
        visibility_level: Gitlab::VisibilityLevel.options['Public']
      )
    end

    it 'does not allow a restricted visibility level for non-admins' do
      project = create_project(user, opts)
      expect(project).to respond_to(:errors)
      expect(project.errors.messages).to have_key(:visibility_level)
      expect(project.errors.messages[:visibility_level].first).to(
        match('restricted by your GitLab administrator')
      )
    end

    it 'allows a restricted visibility level for admins' do
      admin = create(:admin)
      project = create_project(admin, opts)

      expect(project.errors.any?).to be(false)
      expect(project.saved?).to be(true)
    end
  end

  context 'git hook sample' do
    it 'creates git hook from sample' do
      push_rule_sample = create(:push_rule_sample)

      push_rule = create_project(user, opts).push_rule

      [:force_push_regex, :deny_delete_tag, :delete_branch_regex, :commit_message_regex].each do |attr_name|
        expect(push_rule.send(attr_name)).to eq push_rule_sample.send(attr_name)
      end
    end
  end

  context 'repository creation' do
    it 'synchronously creates the repository' do
      expect_any_instance_of(Project).to receive(:create_repository)

      project = create_project(user, opts)
      expect(project).to be_valid
      expect(project.owner).to eq(user)
      expect(project.namespace).to eq(user.namespace)
    end
  end

  context 'when there is an active service template' do
    before do
      create(:service, project: nil, template: true, active: true)
    end

    it 'creates a service from this template' do
      project = create_project(user, opts)

      expect(project.services.count).to eq 1
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end
