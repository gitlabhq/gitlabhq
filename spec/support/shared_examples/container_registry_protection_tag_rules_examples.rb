# frozen_string_literal: true

RSpec.shared_examples 'checking for mutable tag rules' do
  using RSpec::Parameterized::TableSyntax

  context 'when project has matching mutable tag rules for delete and access level' do
    before_all do
      create(:container_registry_protection_tag_rule, tag_name_pattern: 'b',
        minimum_access_level_for_delete: :owner, project: project)
    end

    where(:user_role, :protected_from_delete_with_tags) do
      :guest      | true
      :reporter   | true
      :developer  | true
      :maintainer | true
      :owner      | false
      :admin      | false
    end

    with_them do
      before do
        if user_role == :admin
          allow(current_user).to receive(:can_admin_all_resources?).and_return(true)
        else
          project.send(:"add_#{user_role}", current_user)
        end
      end

      context 'when the project has container registry tags' do
        before do
          allow(project).to receive(:has_container_registry_tags?).and_return(true)
        end

        it { is_expected.to be(protected_from_delete_with_tags) }
      end

      context 'when project has no container registry tags' do
        before do
          allow(project).to receive(:has_container_registry_tags?).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  context 'when project has no matching tag rules for delete and access level' do
    before do
      allow(project).to receive(:has_container_registry_tags?).and_return(true)
    end

    it { is_expected.to be(false) }
  end
end

RSpec.shared_examples 'checking mutable tag rules on a container repository' do
  let(:has_tags) { true }
  before do
    allow(repository).to receive(:has_tags?).and_return(has_tags)
  end

  context 'when the project has mutable tag protection rules' do
    before_all do
      create(
        :container_registry_protection_tag_rule,
        project: project,
        minimum_access_level_for_delete: Gitlab::Access::OWNER
      )
    end

    context 'for admin' do
      before do
        allow(current_user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it { is_expected.to be(false) }
    end

    context 'when the user has a lower access level' do
      before_all do
        project.add_maintainer(current_user)
      end

      it { is_expected.to be(true) }

      context 'when the container repository does not have tags' do
        let(:has_tags) { false }

        it { is_expected.to be(false) }
      end
    end

    context 'when the user meets the minimum access level' do
      before_all do
        project.add_owner(current_user)
      end

      it { is_expected.to be(false) }
    end
  end

  context 'when the project does not have mutable tag protection rules' do
    it { is_expected.to be(false) }
  end
end
