# frozen_string_literal: true

RSpec.shared_examples 'snippet visibility' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:author) { create(:user) }
  let_it_be(:member) { create(:user) }
  let_it_be(:external) { create(:user, :external) }
  let_it_be(:non_member) { create(:user) }

  let_it_be(:project, reload: true) do
    create(:project, :public).tap do |project|
      project.add_developer(author)
      project.add_developer(member)
    end
  end

  let(:snippets) do
    {
      private: private_snippet,
      public: public_snippet,
      internal: internal_snippet
    }
  end

  let(:user) { users[user_type] }
  let(:snippet) { snippets[snippet_visibility] }

  context "For project snippets" do
    let_it_be(:private_snippet) { create(:project_snippet, :private, project: project, author: author) }
    let_it_be(:public_snippet) { create(:project_snippet, :public, project: project, author: author) }
    let_it_be(:internal_snippet) { create(:project_snippet, :internal, project: project, author: author) }

    let!(:users) do
      {
        unauthenticated: nil,
        external: external,
        non_member: non_member,
        member: member,
        author: author
      }
    end

    where(:project_visibility, :feature_visibility, :user_type, :snippet_visibility, :outcome) do
      [
        # Public projects
        [:public, :enabled, :unauthenticated,    :public,   true],
        [:public, :enabled, :unauthenticated,    :internal, false],
        [:public, :enabled, :unauthenticated,    :private,  false],

        [:public, :enabled, :external,           :public,   true],
        [:public, :enabled, :external,           :internal, false],
        [:public, :enabled, :external,           :private,  false],

        [:public, :enabled, :non_member,         :public,   true],
        [:public, :enabled, :non_member,         :internal, true],
        [:public, :enabled, :non_member,         :private,  false],

        [:public, :enabled, :member,             :public,   true],
        [:public, :enabled, :member,             :internal, true],
        [:public, :enabled, :member,             :private,  true],

        [:public, :enabled, :author,             :public,   true],
        [:public, :enabled, :author,             :internal, true],
        [:public, :enabled, :author,             :private,  true],

        [:public, :private, :unauthenticated,    :public,   false],
        [:public, :private, :unauthenticated,    :internal, false],
        [:public, :private, :unauthenticated,    :private,  false],

        [:public, :private, :external,           :public,   false],
        [:public, :private, :external,           :internal, false],
        [:public, :private, :external,           :private,  false],

        [:public, :private, :non_member,         :public,   false],
        [:public, :private, :non_member,         :internal, false],
        [:public, :private, :non_member,         :private,  false],

        [:public, :private, :member,             :public,   true],
        [:public, :private, :member,             :internal, true],
        [:public, :private, :member,             :private,  true],

        [:public, :private, :author,             :public,   true],
        [:public, :private, :author,             :internal, true],
        [:public, :private, :author,             :private,  true],

        [:public, :disabled, :unauthenticated,   :public,   false],
        [:public, :disabled, :unauthenticated,   :internal, false],
        [:public, :disabled, :unauthenticated,   :private,  false],

        [:public, :disabled, :external,          :public,   false],
        [:public, :disabled, :external,          :internal, false],
        [:public, :disabled, :external,          :private,  false],

        [:public, :disabled, :non_member,        :public,   false],
        [:public, :disabled, :non_member,        :internal, false],
        [:public, :disabled, :non_member,        :private,  false],

        [:public, :disabled, :member,            :public,   false],
        [:public, :disabled, :member,            :internal, false],
        [:public, :disabled, :member,            :private,  false],

        [:public, :disabled, :author,            :public,   false],
        [:public, :disabled, :author,            :internal, false],
        [:public, :disabled, :author,            :private,  false],

        # Internal projects
        [:internal, :enabled, :unauthenticated,  :public,   false],
        [:internal, :enabled, :unauthenticated,  :internal, false],
        [:internal, :enabled, :unauthenticated,  :private,  false],

        [:internal, :enabled, :external,         :public,   false],
        [:internal, :enabled, :external,         :internal, false],
        [:internal, :enabled, :external,         :private,  false],

        [:internal, :enabled, :non_member,       :public,   true],
        [:internal, :enabled, :non_member,       :internal, true],
        [:internal, :enabled, :non_member,       :private,  false],

        [:internal, :enabled, :member,           :public,   true],
        [:internal, :enabled, :member,           :internal, true],
        [:internal, :enabled, :member,           :private,  true],

        [:internal, :enabled, :author,           :public,   true],
        [:internal, :enabled, :author,           :internal, true],
        [:internal, :enabled, :author,           :private,  true],

        [:internal, :private, :unauthenticated,  :public,   false],
        [:internal, :private, :unauthenticated,  :internal, false],
        [:internal, :private, :unauthenticated,  :private,  false],

        [:internal, :private, :external,         :public,   false],
        [:internal, :private, :external,         :internal, false],
        [:internal, :private, :external,         :private,  false],

        [:internal, :private, :non_member,       :public,   false],
        [:internal, :private, :non_member,       :internal, false],
        [:internal, :private, :non_member,       :private,  false],

        [:internal, :private, :member,           :public,   true],
        [:internal, :private, :member,           :internal, true],
        [:internal, :private, :member,           :private,  true],

        [:internal, :private, :author,           :public,   true],
        [:internal, :private, :author,           :internal, true],
        [:internal, :private, :author,           :private,  true],

        [:internal, :disabled, :unauthenticated, :public,   false],
        [:internal, :disabled, :unauthenticated, :internal, false],
        [:internal, :disabled, :unauthenticated, :private,  false],

        [:internal, :disabled, :external,        :public,   false],
        [:internal, :disabled, :external,        :internal, false],
        [:internal, :disabled, :external,        :private,  false],

        [:internal, :disabled, :non_member,      :public,   false],
        [:internal, :disabled, :non_member,      :internal, false],
        [:internal, :disabled, :non_member,      :private,  false],

        [:internal, :disabled, :member,          :public,   false],
        [:internal, :disabled, :member,          :internal, false],
        [:internal, :disabled, :member,          :private,  false],

        [:internal, :disabled, :author,          :public,   false],
        [:internal, :disabled, :author,          :internal, false],
        [:internal, :disabled, :author,          :private,  false],

        # Private projects
        [:private, :enabled, :unauthenticated,   :public,   false],
        [:private, :enabled, :unauthenticated,   :internal, false],
        [:private, :enabled, :unauthenticated,   :private,  false],

        [:private, :enabled, :external,          :public,   true],
        [:private, :enabled, :external,          :internal, true],
        [:private, :enabled, :external,          :private,  true],

        [:private, :enabled, :non_member,        :public,   false],
        [:private, :enabled, :non_member,        :internal, false],
        [:private, :enabled, :non_member,        :private,  false],

        [:private, :enabled, :member,            :public,   true],
        [:private, :enabled, :member,            :internal, true],
        [:private, :enabled, :member,            :private,  true],

        [:private, :enabled, :author,            :public,   true],
        [:private, :enabled, :author,            :internal, true],
        [:private, :enabled, :author,            :private,  true],

        [:private, :private, :unauthenticated,   :public,   false],
        [:private, :private, :unauthenticated,   :internal, false],
        [:private, :private, :unauthenticated,   :private,  false],

        [:private, :private, :external,          :public,   true],
        [:private, :private, :external,          :internal, true],
        [:private, :private, :external,          :private,  true],

        [:private, :private, :non_member,        :public,   false],
        [:private, :private, :non_member,        :internal, false],
        [:private, :private, :non_member,        :private,  false],

        [:private, :private, :member,            :public,   true],
        [:private, :private, :member,            :internal, true],
        [:private, :private, :member,            :private,  true],

        [:private, :private, :author,            :public,   true],
        [:private, :private, :author,            :internal, true],
        [:private, :private, :author,            :private,  true],

        [:private, :disabled, :unauthenticated,  :public,   false],
        [:private, :disabled, :unauthenticated,  :internal, false],
        [:private, :disabled, :unauthenticated,  :private,  false],

        [:private, :disabled, :external,         :public,   false],
        [:private, :disabled, :external,         :internal, false],
        [:private, :disabled, :external,         :private,  false],

        [:private, :disabled, :non_member,       :public,   false],
        [:private, :disabled, :non_member,       :internal, false],
        [:private, :disabled, :non_member,       :private,  false],

        [:private, :disabled, :member,           :public,   false],
        [:private, :disabled, :member,           :internal, false],
        [:private, :disabled, :member,           :private,  false],

        [:private, :disabled, :author,           :public,   false],
        [:private, :disabled, :author,           :internal, false],
        [:private, :disabled, :author,           :private,  false]
      ]
    end

    with_them do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel.level_value(project_visibility.to_s), snippets_access_level: feature_visibility)

        if user_type == :external
          member = project.member(external)

          if project.private?
            project.add_developer(external) unless member
          elsif member
            member.delete
          end
        end
      end

      context "For #{params[:project_type]} project and #{params[:user_type]} users" do
        it 'returns proper outcome' do
          expect(can?(user, :read_snippet, snippet)).to eq(outcome)

          results = described_class.new(user, project: project).execute

          expect(results.include?(snippet)).to eq(outcome)
        end
      end

      context "Without a given project and #{params[:user_type]} users" do
        it 'returns proper outcome' do
          results = described_class.new(user).execute

          expect(results.include?(snippet)).to eq(outcome)
        end
      end
    end
  end

  context 'For personal snippets' do
    let!(:users) do
      {
        unauthenticated: nil,
        external: external,
        non_member: non_member,
        author: author
      }
    end

    where(:snippet_visibility, :user_type, :outcome) do
      [
        [:public,   :unauthenticated, true],
        [:public,   :external,        true],
        [:public,   :non_member,      true],
        [:public,   :author,          true],

        [:internal, :unauthenticated, false],
        [:internal, :external,        false],
        [:internal, :non_member,      true],
        [:internal, :author,          true],

        [:private,  :unauthenticated, false],
        [:private,  :external,        false],
        [:private,  :non_member,      false],
        [:private,  :author,          true]
      ]
    end

    with_them do
      let_it_be(:private_snippet) { create(:personal_snippet, :private, author: author) }
      let_it_be(:public_snippet) { create(:personal_snippet, :public, author: author) }
      let_it_be(:internal_snippet) { create(:personal_snippet, :internal, author: author) }

      context "For personal and #{params[:snippet_visibility]} snippets with #{params[:user_type]} user" do
        it 'returns proper outcome' do
          expect(can?(user, :read_snippet, snippet)).to eq(outcome)

          results = described_class.new(user).execute

          expect(results.include?(snippet)).to eq(outcome)
        end
      end
    end
  end

  context 'when the user cannot read cross project' do
    it 'returns only personal snippets' do
      personal_snippet = create(:personal_snippet, :public, author: author)
      create(:project_snippet, :public, project: project, author: author)

      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(author, :read_cross_project) { false }

      service = described_class.new(author)

      expect(service).to receive(:personal_snippets).and_call_original
      expect(service).not_to receive(:snippets_of_visible_projects)
      expect(service).not_to receive(:snippets_of_authorized_projects)

      expect(service.execute).to match_array([personal_snippet])
    end
  end
end
