# frozen_string_literal: true

RSpec.shared_examples 'archived project policies' do
  let(:feature_write_abilities) do
    described_class.readonly_features.flat_map do |feature|
      described_class.create_update_admin_destroy(feature)
    end + additional_maintainer_permissions
  end

  let(:other_write_abilities) do
    described_class.readonly_abilities
  end

  context 'when the project is archived' do
    before do
      project.archived = true
    end

    it 'disables write actions on all relevant project features' do
      expect_disallowed(*feature_write_abilities)
    end

    it 'disables some other important write actions' do
      expect_disallowed(*other_write_abilities)
    end

    it 'does not disable other abilities' do
      expect_allowed(*(regular_abilities - feature_write_abilities - other_write_abilities))
    end
  end
end

RSpec.shared_examples 'project private features with read_all_resources ability' do
  subject { described_class.new(user, project) }

  before do
    project.project_feature.update!(
      repository_access_level: ProjectFeature::PRIVATE,
      merge_requests_access_level: ProjectFeature::PRIVATE,
      builds_access_level: ProjectFeature::PRIVATE
    )
  end

  [:public, :internal, :private].each do |visibility|
    context "for #{visibility} projects" do
      let(:project) { create(:project, visibility, namespace: owner.namespace) }

      it 'allows the download_code ability' do
        expect_allowed(:download_code)
      end
    end
  end
end

RSpec.shared_examples 'project policies as anonymous' do
  context 'abilities for public projects' do
    context 'when a project has pending invites' do
      let(:group) { create(:group, :public) }
      let(:project) { create(:project, :public, namespace: group) }
      let(:user_permissions) { [:create_merge_request_in, :create_project, :create_issue, :create_note, :upload_file, :award_emoji, :create_incident] }
      let(:anonymous_permissions) { guest_permissions - user_permissions }
      let(:current_user) { anonymous }

      before do
        create(:group_member, :invited, group: group)
      end

      it 'does not grant owner access' do
        expect_allowed(*anonymous_permissions)
        expect_disallowed(*user_permissions)
      end

      it_behaves_like 'archived project policies' do
        let(:regular_abilities) { anonymous_permissions }
      end
    end
  end

  context 'abilities for non-public projects' do
    let(:project) { private_project }
    let(:current_user) { anonymous }

    it { is_expected.to be_banned }
  end
end

RSpec.shared_examples 'deploy token does not get confused with user' do
  before do
    deploy_token.update!(id: user_id)

    # Project with public builds are available to all
    project.update!(public_builds: false)
  end

  let(:deploy_token) { create(:deploy_token) }

  subject { described_class.new(deploy_token, project) }

  it do
    expect_disallowed(*guest_permissions)
    expect_disallowed(*reporter_permissions)
    expect_disallowed(*team_member_reporter_permissions)
    expect_disallowed(*developer_permissions)
    expect_disallowed(*maintainer_permissions)
    expect_disallowed(*owner_permissions)
  end
end

RSpec.shared_examples 'project policies as guest' do
  context 'abilities for non-public projects' do
    let(:project) { private_project }
    let(:current_user) { guest }

    let(:reporter_public_build_permissions) do
      reporter_permissions - [:read_build, :read_pipeline]
    end

    it do
      expect_allowed(*guest_permissions)
      expect_disallowed(*reporter_public_build_permissions)
      expect_disallowed(*team_member_reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { guest.id }
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { guest_permissions }
    end

    context 'public builds enabled' do
      it do
        expect_allowed(*guest_permissions)
        expect_allowed(:read_build, :read_pipeline)
      end
    end

    context 'when public builds disabled' do
      before do
        project.update!(public_builds: false)
      end

      it do
        expect_allowed(*guest_permissions)
        expect_disallowed(:read_build, :read_pipeline)
      end
    end

    context 'when builds are disabled' do
      before do
        project.project_feature.update!(builds_access_level: ProjectFeature::DISABLED)
      end

      it do
        expect_disallowed(:read_build)
        expect_allowed(:read_pipeline)
      end
    end
  end
end

RSpec.shared_examples 'project policies as reporter' do
  context 'abilities for non-public projects' do
    let(:project) { private_project }
    let(:current_user) { reporter }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*team_member_reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { reporter.id }
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { reporter_permissions }
    end
  end
end

RSpec.shared_examples 'project policies as developer' do
  context 'abilities for non-public projects' do
    let(:project) { private_project }
    let(:current_user) { developer }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*team_member_reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { developer.id }
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { developer_permissions }
    end
  end
end

RSpec.shared_examples 'project policies as maintainer' do
  context 'abilities for non-public projects' do
    let(:project) { private_project }
    let(:current_user) { maintainer }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*team_member_reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_allowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { maintainer.id }
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { maintainer_permissions }
    end
  end
end

RSpec.shared_examples 'project policies as owner' do
  context 'abilities for non-public projects' do
    let(:project) { private_project }
    let(:current_user) { owner }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*team_member_reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_allowed(*maintainer_permissions)
      expect_allowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { owner.id }
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { owner_permissions }
    end
  end
end

RSpec.shared_examples 'project policies as admin with admin mode' do
  context 'abilities for non-public projects', :enable_admin_mode do
    let(:project) { private_project }
    let(:current_user) { admin }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_disallowed(*team_member_reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_allowed(*maintainer_permissions)
      expect_allowed(*owner_permissions)
    end

    context 'deploy token does not get confused with user' do
      before do
        allow(deploy_token).to receive(:id).and_return(admin.id)

        # Project with public builds are available to all
        project.update!(public_builds: false)
      end

      let(:deploy_token) { create(:deploy_token) }

      subject { described_class.new(deploy_token, project) }

      it do
        expect_disallowed(*guest_permissions)
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*team_member_reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { owner_permissions }
    end
  end

  context 'abilities for all project visibility', :enable_admin_mode do
    it_behaves_like 'project private features with read_all_resources ability' do
      let(:user) { admin }
    end
  end
end

RSpec.shared_examples 'project policies as admin without admin mode' do
  context 'abilities for non-public projects' do
    let(:project) { private_project }
    let(:current_user) { admin }

    it { is_expected.to be_banned }

    context 'deploy token does not get confused with user' do
      before do
        allow(deploy_token).to receive(:id).and_return(admin.id)

        # Project with public builds are available to all
        project.update!(public_builds: false)
      end

      let(:deploy_token) { create(:deploy_token) }

      subject { described_class.new(deploy_token, project) }

      it { is_expected.to be_banned }
    end
  end
end
