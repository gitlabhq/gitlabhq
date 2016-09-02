require 'spec_helper'

describe Projects::CreateService, services: true do
  describe :create_by_user do
    before do
      @user = create :user
      @opts = {
        name: "GitLab",
        namespace: @user.namespace
      }
    end

    it 'creates services on Project creation' do
      project = create_project(@user, @opts)
      project.reload

      expect(project.services).not_to be_empty
    end

    it 'creates labels on Project creation if there are templates' do
      Label.create(title: "bug", template: true)
      project = create_project(@user, @opts)
      project.reload

      expect(project.labels).not_to be_empty
    end

    context 'user namespace' do
      before do
        @project = create_project(@user, @opts)
      end

      it { expect(@project).to be_valid }
      it { expect(@project.owner).to eq(@user) }
      it { expect(@project.team.masters).to include(@user) }
      it { expect(@project.namespace).to eq(@user.namespace) }
    end

    context 'group namespace' do
      before do
        @group = create :group
        @group.add_owner(@user)

        @opts.merge!(namespace_id: @group.id)
        @project = create_project(@user, @opts)
      end

      it { expect(@project).to be_valid }
      it { expect(@project.owner).to eq(@group) }
      it { expect(@project.namespace).to eq(@group) }
    end

    context 'error handling' do
      it 'handles invalid options' do
        @opts.merge!({ default_branch: 'master' } )
        expect(create_project(@user, @opts)).to eq(nil)
      end
    end

    context 'wiki_enabled creates repository directory' do
      context 'wiki_enabled true creates wiki repository directory' do
        before do
          @project = create_project(@user, @opts)
          @path = ProjectWiki.new(@project, @user).send(:path_to_repo)
        end

        it { expect(File.exist?(@path)).to be_truthy }
      end

      context 'wiki_enabled false does not create wiki repository directory' do
        before do
          @opts.merge!( { project_feature_attributes: { wiki_access_level: ProjectFeature::DISABLED } })
          @project = create_project(@user, @opts)
          @path = ProjectWiki.new(@project, @user).send(:path_to_repo)
        end

        it { expect(File.exist?(@path)).to be_falsey }
      end
    end

    context 'builds_enabled global setting' do
      let(:project) { create_project(@user, @opts) }

      subject { project.builds_enabled? }

      context 'global builds_enabled false does not enable CI by default' do
        before do
          project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
        end

        it { is_expected.to be_falsey }
      end

      context 'global builds_enabled true does enable CI by default' do
        before do
          project.project_feature.update_attribute(:builds_access_level, ProjectFeature::ENABLED)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'restricted visibility level' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

        @opts.merge!(
          visibility_level: Gitlab::VisibilityLevel.options['Public']
        )
      end

      it 'does not allow a restricted visibility level for non-admins' do
        project = create_project(@user, @opts)
        expect(project).to respond_to(:errors)
        expect(project.errors.messages).to have_key(:visibility_level)
        expect(project.errors.messages[:visibility_level].first).to(
          match('restricted by your GitLab administrator')
        )
      end

      it 'allows a restricted visibility level for admins' do
        admin = create(:admin)
        project = create_project(admin, @opts)

        expect(project.errors.any?).to be(false)
        expect(project.saved?).to be(true)
      end
    end

    context "git hook sample" do
      before do
        @push_rule_sample = create :push_rule_sample
      end

      it "creates git hook from sample" do
        push_rule = create_project(@user, @opts).push_rule
        [:force_push_regex, :deny_delete_tag, :delete_branch_regex, :commit_message_regex].each do |attr_name|
          expect(push_rule.send(attr_name)).to eq @push_rule_sample.send(attr_name)
        end
      end
    end

    context 'repository creation' do
      it 'synchronously creates the repository' do
        expect_any_instance_of(Project).to receive(:create_repository)

        project = create_project(@user, @opts)
        expect(project).to be_valid
        expect(project.owner).to eq(@user)
        expect(project.namespace).to eq(@user.namespace)
      end
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end
