# frozen_string_literal: true

RSpec.shared_examples 'model with wiki policies' do
  let(:container) { raise NotImplementedError }
  let(:permissions) { %i(read_wiki create_wiki update_wiki admin_wiki download_wiki_code) }

  # TODO: Remove this helper once we implement group features
  # https://gitlab.com/gitlab-org/gitlab/-/issues/208412
  def set_access_level(access_level)
    raise NotImplementedError
  end

  subject { described_class.new(owner, container) }

  context 'when the feature is disabled' do
    before do
      set_access_level(ProjectFeature::DISABLED)
    end

    it 'does not include the wiki permissions' do
      expect_disallowed(*permissions)
    end

    context 'when there is an external wiki' do
      it 'does not include the wiki permissions' do
        allow(container).to receive(:has_external_wiki?).and_return(true)

        expect_disallowed(*permissions)
      end
    end
  end

  describe 'read_wiki' do
    subject { described_class.new(user, container) }

    member_roles = %i[guest developer]
    stranger_roles = %i[anonymous non_member]

    user_roles = stranger_roles + member_roles

    # When a user is anonymous, their `current_user == nil`
    let(:user) { create(:user) unless user_role == :anonymous }

    before do
      container.visibility = container_visibility
      set_access_level(wiki_access_level)
      container.add_user(user, user_role) if member_roles.include?(user_role)
    end

    title = ->(container_visibility, wiki_access_level, user_role) do
      [
        "container is #{Gitlab::VisibilityLevel.level_name container_visibility}",
        "wiki is #{ProjectFeature.str_from_access_level wiki_access_level}",
        "user is #{user_role}"
      ].join(', ')
    end

    describe 'Situations where :read_wiki is always false' do
      where(case_names: title,
            container_visibility: Gitlab::VisibilityLevel.options.values,
            wiki_access_level: [ProjectFeature::DISABLED],
            user_role: user_roles)

      with_them do
        it { is_expected.to be_disallowed(:read_wiki) }
      end
    end

    describe 'Situations where :read_wiki is always true' do
      where(case_names: title,
            container_visibility: [Gitlab::VisibilityLevel::PUBLIC],
            wiki_access_level: [ProjectFeature::ENABLED],
            user_role: user_roles)

      with_them do
        it { is_expected.to be_allowed(:read_wiki) }
      end
    end

    describe 'Situations where :read_wiki requires membership' do
      context 'the wiki is private, and the user is a member' do
        where(case_names: title,
              container_visibility: [Gitlab::VisibilityLevel::PUBLIC,
                                     Gitlab::VisibilityLevel::INTERNAL],
              wiki_access_level: [ProjectFeature::PRIVATE],
              user_role: member_roles)

        with_them do
          it { is_expected.to be_allowed(:read_wiki) }
        end
      end

      context 'the wiki is private, and the user is not member' do
        where(case_names: title,
              container_visibility: [Gitlab::VisibilityLevel::PUBLIC,
                                     Gitlab::VisibilityLevel::INTERNAL],
              wiki_access_level: [ProjectFeature::PRIVATE],
              user_role: stranger_roles)

        with_them do
          it { is_expected.to be_disallowed(:read_wiki) }
        end
      end

      context 'the wiki is enabled, and the user is a member' do
        where(case_names: title,
              container_visibility: [Gitlab::VisibilityLevel::PRIVATE],
              wiki_access_level: [ProjectFeature::ENABLED],
              user_role: member_roles)

        with_them do
          it { is_expected.to be_allowed(:read_wiki) }
        end
      end

      context 'the wiki is enabled, and the user is not a member' do
        where(case_names: title,
              container_visibility: [Gitlab::VisibilityLevel::PRIVATE],
              wiki_access_level: [ProjectFeature::ENABLED],
              user_role: stranger_roles)

        with_them do
          it { is_expected.to be_disallowed(:read_wiki) }
        end
      end
    end

    describe 'Situations where :read_wiki prohibits anonymous access' do
      context 'the user is not anonymous' do
        where(case_names: title,
              container_visibility: [Gitlab::VisibilityLevel::INTERNAL],
              wiki_access_level: [ProjectFeature::ENABLED, ProjectFeature::PUBLIC],
              user_role: user_roles.reject { |u| u == :anonymous })

        with_them do
          it { is_expected.to be_allowed(:read_wiki) }
        end
      end

      context 'the user is anonymous' do
        where(case_names: title,
              container_visibility: [Gitlab::VisibilityLevel::INTERNAL],
              wiki_access_level: [ProjectFeature::ENABLED, ProjectFeature::PUBLIC],
              user_role: %i[anonymous])

        with_them do
          it { is_expected.to be_disallowed(:read_wiki) }
        end
      end
    end
  end
end
