RSpec.shared_examples 'snippet visibility' do
  context "For project snippets" do
    let!(:author) { create(:user) }
    let!(:member) { create(:user) }
    let!(:external) { create(:user, :external) }
    let!(:public_project) { create(:project, :public) }
    let!(:internal_project) { create(:project, :internal) }
    let!(:private_project) { create(:project, :private) }

    let!(:users) do
      {
        unauthenticated: nil,
        external: external,
        non_member: create(:user),
        member: member,
        author: author
      }
    end

    let!(:project_types) do
      {
        public: public_project,
        internal: internal_project,
        private: private_project
      }
    end

    let!(:members) do
      project_types.values.each do |project_type|
        project_type.team << [author, :developer]
        project_type.team << [member, :developer]
        project_type.team << [external, :developer] if project_type.private?
      end
    end

    let!(:snippets) do
      {
        public_project: {
          snippet_public: create(:project_snippet, :public, project: public_project, author: author),
          snippet_internal: create(:project_snippet, :internal, project: public_project, author: author),
          snippet_private: create(:project_snippet, :private, project: public_project, author: author)
        },
        internal_project: {
          snippet_public: create(:project_snippet, :public, project: internal_project, author: author),
          snippet_internal: create(:project_snippet, :internal, project: internal_project, author: author),
          snippet_private: create(:project_snippet, :private, project: internal_project, author: author)
        },
        private_project: {
          snippet_public: create(:project_snippet, :public, project: private_project, author: author),
          snippet_internal: create(:project_snippet, :internal, project: private_project, author: author),
          snippet_private: create(:project_snippet, :private, project: private_project, author: author)
        }
      }
    end

    let(:project_feature_visibilities) do
      {
        enabled: ProjectFeature::ENABLED,
        private: ProjectFeature::PRIVATE,
        disabled: ProjectFeature::DISABLED
      }
    end

    where(:project_type, :feature_visibility, :current_user, :snippet_type, :outcome) do
      [
        # Public projects
        [:public, :enabled, :unauthenticated,    :snippet_public,   true],
        [:public, :enabled, :unauthenticated,    :snippet_internal, false],
        [:public, :enabled, :unauthenticated,    :snippet_private,  false],

        [:public, :enabled, :external,           :snippet_public,   true],
        [:public, :enabled, :external,           :snippet_internal, false],
        [:public, :enabled, :external,           :snippet_private,  false],

        [:public, :enabled, :non_member,         :snippet_public,   true],
        [:public, :enabled, :non_member,         :snippet_internal, true],
        [:public, :enabled, :non_member,         :snippet_private,  false],

        [:public, :enabled, :member,             :snippet_public,   true],
        [:public, :enabled, :member,             :snippet_internal, true],
        [:public, :enabled, :member,             :snippet_private,  true],

        [:public, :enabled, :author,             :snippet_public,   true],
        [:public, :enabled, :author,             :snippet_internal, true],
        [:public, :enabled, :author,             :snippet_private,  true],

        [:public, :private, :unauthenticated,    :snippet_public,   false],
        [:public, :private, :unauthenticated,    :snippet_internal, false],
        [:public, :private, :unauthenticated,    :snippet_private,  false],

        [:public, :private, :external,           :snippet_public,   false],
        [:public, :private, :external,           :snippet_internal, false],
        [:public, :private, :external,           :snippet_private,  false],

        [:public, :private, :non_member,         :snippet_public,   false],
        [:public, :private, :non_member,         :snippet_internal, false],
        [:public, :private, :non_member,         :snippet_private,  false],

        [:public, :private, :member,             :snippet_public,   true],
        [:public, :private, :member,             :snippet_internal, true],
        [:public, :private, :member,             :snippet_private,  true],

        [:public, :private, :author,             :snippet_public,   true],
        [:public, :private, :author,             :snippet_internal, true],
        [:public, :private, :author,             :snippet_private,  true],

        [:public, :disabled, :unauthenticated,   :snippet_public,   false],
        [:public, :disabled, :unauthenticated,   :snippet_internal, false],
        [:public, :disabled, :unauthenticated,   :snippet_private,  false],

        [:public, :disabled, :external,          :snippet_public,   false],
        [:public, :disabled, :external,          :snippet_internal, false],
        [:public, :disabled, :external,          :snippet_private,  false],

        [:public, :disabled, :non_member,        :snippet_public,   false],
        [:public, :disabled, :non_member,        :snippet_internal, false],
        [:public, :disabled, :non_member,        :snippet_private,  false],

        [:public, :disabled, :member,            :snippet_public,   false],
        [:public, :disabled, :member,            :snippet_internal, false],
        [:public, :disabled, :member,            :snippet_private,  false],

        [:public, :disabled, :author,            :snippet_public,   false],
        [:public, :disabled, :author,            :snippet_internal, false],
        [:public, :disabled, :author,            :snippet_private,  false],

        # Internal projects
        [:internal, :enabled, :unauthenticated,  :snippet_public,   false],
        [:internal, :enabled, :unauthenticated,  :snippet_internal, false],
        [:internal, :enabled, :unauthenticated,  :snippet_private,  false],

        [:internal, :enabled, :external,         :snippet_public,   false],
        [:internal, :enabled, :external,         :snippet_internal, false],
        [:internal, :enabled, :external,         :snippet_private,  false],

        [:internal, :enabled, :non_member,       :snippet_public,   true],
        [:internal, :enabled, :non_member,       :snippet_internal, true],
        [:internal, :enabled, :non_member,       :snippet_private,  false],

        [:internal, :enabled, :member,           :snippet_public,   true],
        [:internal, :enabled, :member,           :snippet_internal, true],
        [:internal, :enabled, :member,           :snippet_private,  true],

        [:internal, :enabled, :author,           :snippet_public,   true],
        [:internal, :enabled, :author,           :snippet_internal, true],
        [:internal, :enabled, :author,           :snippet_private,  true],

        [:internal, :private, :unauthenticated,  :snippet_public,   false],
        [:internal, :private, :unauthenticated,  :snippet_internal, false],
        [:internal, :private, :unauthenticated,  :snippet_private,  false],

        [:internal, :private, :external,         :snippet_public,   false],
        [:internal, :private, :external,         :snippet_internal, false],
        [:internal, :private, :external,         :snippet_private,  false],

        [:internal, :private, :non_member,       :snippet_public,   false],
        [:internal, :private, :non_member,       :snippet_internal, false],
        [:internal, :private, :non_member,       :snippet_private,  false],

        [:internal, :private, :member,           :snippet_public,   true],
        [:internal, :private, :member,           :snippet_internal, true],
        [:internal, :private, :member,           :snippet_private,  true],

        [:internal, :private, :author,           :snippet_public,   true],
        [:internal, :private, :author,           :snippet_internal, true],
        [:internal, :private, :author,           :snippet_private,  true],

        [:internal, :disabled, :unauthenticated, :snippet_public,   false],
        [:internal, :disabled, :unauthenticated, :snippet_internal, false],
        [:internal, :disabled, :unauthenticated, :snippet_private,  false],

        [:internal, :disabled, :external,        :snippet_public,   false],
        [:internal, :disabled, :external,        :snippet_internal, false],
        [:internal, :disabled, :external,        :snippet_private,  false],

        [:internal, :disabled, :non_member,      :snippet_public,   false],
        [:internal, :disabled, :non_member,      :snippet_internal, false],
        [:internal, :disabled, :non_member,      :snippet_private,  false],

        [:internal, :disabled, :member,          :snippet_public,   false],
        [:internal, :disabled, :member,          :snippet_internal, false],
        [:internal, :disabled, :member,          :snippet_private,  false],

        [:internal, :disabled, :author,          :snippet_public,   false],
        [:internal, :disabled, :author,          :snippet_internal, false],
        [:internal, :disabled, :author,          :snippet_private,  false],

        # Private projects
        [:private, :enabled, :unauthenticated,   :snippet_public,   false],
        [:private, :enabled, :unauthenticated,   :snippet_internal, false],
        [:private, :enabled, :unauthenticated,   :snippet_private,  false],

        [:private, :enabled, :external,          :snippet_public,   true],
        [:private, :enabled, :external,          :snippet_internal, true],
        [:private, :enabled, :external,          :snippet_private,  true],

        [:private, :enabled, :non_member,        :snippet_public,   false],
        [:private, :enabled, :non_member,        :snippet_internal, false],
        [:private, :enabled, :non_member,        :snippet_private,  false],

        [:private, :enabled, :member,            :snippet_public,   true],
        [:private, :enabled, :member,            :snippet_internal, true],
        [:private, :enabled, :member,            :snippet_private,  true],

        [:private, :enabled, :author,            :snippet_public,   true],
        [:private, :enabled, :author,            :snippet_internal, true],
        [:private, :enabled, :author,            :snippet_private,  true],

        [:private, :private, :unauthenticated,   :snippet_public,   false],
        [:private, :private, :unauthenticated,   :snippet_internal, false],
        [:private, :private, :unauthenticated,   :snippet_private,  false],

        [:private, :private, :external,          :snippet_public,   true],
        [:private, :private, :external,          :snippet_internal, true],
        [:private, :private, :external,          :snippet_private,  true],

        [:private, :private, :non_member,        :snippet_public,   false],
        [:private, :private, :non_member,        :snippet_internal, false],
        [:private, :private, :non_member,        :snippet_private,  false],

        [:private, :private, :member,            :snippet_public,   true],
        [:private, :private, :member,            :snippet_internal, true],
        [:private, :private, :member,            :snippet_private,  true],

        [:private, :private, :author,            :snippet_public,   true],
        [:private, :private, :author,            :snippet_internal, true],
        [:private, :private, :author,            :snippet_private,  true],

        [:private, :disabled, :unauthenticated,  :snippet_public,   false],
        [:private, :disabled, :unauthenticated,  :snippet_internal, false],
        [:private, :disabled, :unauthenticated,  :snippet_private,  false],

        [:private, :disabled, :external,         :snippet_public,   false],
        [:private, :disabled, :external,         :snippet_internal, false],
        [:private, :disabled, :external,         :snippet_private,  false],

        [:private, :disabled, :non_member,       :snippet_public,   false],
        [:private, :disabled, :non_member,       :snippet_internal, false],
        [:private, :disabled, :non_member,       :snippet_private,  false],

        [:private, :disabled, :member,           :snippet_public,   false],
        [:private, :disabled, :member,           :snippet_internal, false],
        [:private, :disabled, :member,           :snippet_private,  false],

        [:private, :disabled, :author,           :snippet_public,   false],
        [:private, :disabled, :author,           :snippet_internal, false],
        [:private, :disabled, :author,           :snippet_private,  false]
      ]
    end

    with_them do
      before do
        @project = project_types[project_type]
        @project.project_feature.update_column(:snippets_access_level, project_feature_visibilities[feature_visibility])
        @user = users[current_user]
      end

      context "For #{params[:project_type]} project and #{params[:current_user]} users" do
        it 'should agree with the read_project_snippet policy' do
          snippet = snippets["#{project_type}_project".to_sym][snippet_type]
          expect(can?(@user, :read_project_snippet, snippet)).to eq(outcome)
        end

        it 'should return proper outcome' do
          results = described_class.new(@user, project: @project).execute
          snippet = snippets["#{project_type}_project".to_sym][snippet_type]
          expect(results.include?(snippet)).to eq(outcome)
        end
      end

      context "Without a given project and #{params[:current_user]} users" do
        it 'should return proper outcome' do
          results = described_class.new(@user).execute
          snippet = snippets["#{project_type}_project".to_sym][snippet_type]
          expect(results.include?(snippet)).to eq(outcome)
        end
      end
    end
  end

  context 'For personal snippets' do
    let!(:author) { create(:user) }
    let!(:external) { create(:user, :external) }
    let!(:public_project) { create(:project, :public) }
    let!(:internal_project) { create(:project, :internal) }
    let!(:private_project) { create(:project, :private) }

    let!(:users) do
      {
        unauthenticated: nil,
        external: external,
        author: author
      }
    end

    let!(:snippets) do
      {
        personal: {
          public: create(:personal_snippet, :public, author: author),
          internal: create(:personal_snippet, :internal, author: author),
          private: create(:personal_snippet, :private, author: author)
        }
      }
    end

    let!(:other_snippets) do
      [public_project, internal_project, private_project].each do |project|
        create(:project_snippet, :public, author: author, project: project)
        create(:project_snippet, :internal, author: author, project: project)
        create(:project_snippet, :private, author: author, project: project)
      end
    end

    where(:snippet_type, :snippet_visibility, :current_user, :outcome) do
      [
        # Personal snippets
        [:personal, :public,   :unauthenticated, true],
        [:personal, :public,   :external,        true],
        [:personal, :public,   :author,          true],

        [:personal, :internal, :unauthenticated, false],
        [:personal, :internal, :external,        false],
        [:personal, :internal, :author,          true],

        [:personal, :private,  :unauthenticated, false],
        [:personal, :private,  :external,        false],
        [:personal, :private,  :author,          true]
      ]
    end

    with_them do
      context "For personal and #{params[:snippet_visibility]} snippets with #{params[:current_user]} user" do
        it 'should agree with read_personal_snippet policy' do
          user = users[current_user]
          snippet = snippets[snippet_type][snippet_visibility]

          expect(can?(user, :read_personal_snippet, snippet)).to eq(outcome)
        end

        it 'should return proper outcome' do
          user = users[current_user]

          results = described_class.new(user).execute
          snippet = snippets[snippet_type][snippet_visibility]
          expect(results.include?(snippet)).to eq(outcome)
        end
      end
    end
  end
end
