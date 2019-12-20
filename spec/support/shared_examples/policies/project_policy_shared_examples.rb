# frozen_string_literal: true

RSpec.shared_examples 'archived project policies' do
  let(:feature_write_abilities) do
    described_class::READONLY_FEATURES_WHEN_ARCHIVED.flat_map do |feature|
      described_class.create_update_admin_destroy(feature)
    end + additional_maintainer_permissions
  end

  let(:other_write_abilities) do
    %i[
      create_merge_request_in
      create_merge_request_from
      push_to_delete_protected_branch
      push_code
      request_access
      upload_file
      resolve_note
      award_emoji
      admin_tag
      admin_issue_link
    ]
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

RSpec.shared_examples 'project policies as anonymous' do
  context 'abilities for public projects' do
    context 'when a project has pending invites' do
      let(:group) { create(:group, :public) }
      let(:project) { create(:project, :public, namespace: group) }
      let(:user_permissions) { [:create_merge_request_in, :create_project, :create_issue, :create_note, :upload_file, :award_emoji] }
      let(:anonymous_permissions) { guest_permissions - user_permissions }

      subject { described_class.new(nil, project) }

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
    let(:project) { create(:project, namespace: owner.namespace) }

    subject { described_class.new(nil, project) }

    it { is_expected.to be_banned }
  end
end

RSpec.shared_examples 'project policies as guest' do
  subject { described_class.new(guest, project) }

  context 'abilities for non-public projects' do
    let(:project) { create(:project, namespace: owner.namespace) }
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
        project.update(public_builds: false)
      end

      it do
        expect_allowed(*guest_permissions)
        expect_disallowed(:read_build, :read_pipeline)
      end
    end

    context 'when builds are disabled' do
      before do
        project.project_feature.update(builds_access_level: ProjectFeature::DISABLED)
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
    let(:project) { create(:project, namespace: owner.namespace) }

    subject { described_class.new(reporter, project) }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*team_member_reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { reporter_permissions }
    end
  end
end

RSpec.shared_examples 'project policies as developer' do
  context 'abilities for non-public projects' do
    let(:project) { create(:project, namespace: owner.namespace) }

    subject { described_class.new(developer, project) }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*team_member_reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { developer_permissions }
    end
  end
end

RSpec.shared_examples 'project policies as maintainer' do
  context 'abilities for non-public projects' do
    let(:project) { create(:project, namespace: owner.namespace) }

    subject { described_class.new(maintainer, project) }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*team_member_reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_allowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { maintainer_permissions }
    end
  end
end

RSpec.shared_examples 'project policies as owner' do
  context 'abilities for non-public projects' do
    let(:project) { create(:project, namespace: owner.namespace) }

    subject { described_class.new(owner, project) }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*team_member_reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_allowed(*maintainer_permissions)
      expect_allowed(*owner_permissions)
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { owner_permissions }
    end
  end
end

RSpec.shared_examples 'project policies as admin' do
  context 'abilities for non-public projects' do
    let(:project) { create(:project, namespace: owner.namespace) }

    subject { described_class.new(admin, project) }

    it do
      expect_allowed(*guest_permissions)
      expect_allowed(*reporter_permissions)
      expect_disallowed(*team_member_reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_allowed(*maintainer_permissions)
      expect_allowed(*owner_permissions)
    end

    it_behaves_like 'archived project policies' do
      let(:regular_abilities) { owner_permissions }
    end
  end
end
