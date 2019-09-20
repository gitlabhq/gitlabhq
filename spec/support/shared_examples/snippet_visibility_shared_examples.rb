# frozen_string_literal: true

RSpec.shared_examples 'snippet visibility' do
  using RSpec::Parameterized::TableSyntax

  # Make sure no snippets exist prior to running the test matrix
  before(:context) do
    DatabaseCleaner.clean_with(:truncation)
  end

  set(:author) { create(:user) }
  set(:member) { create(:user) }
  set(:external) { create(:user, :external) }

  context "For project snippets" do
    let!(:users) do
      {
        unauthenticated: nil,
        external: external,
        non_member: create(:user),
        member: member,
        author: author
      }
    end

    where(:project_type, :feature_visibility, :user_type, :snippet_type, :outcome) do
      [
        # Public projects
        [:public, ProjectFeature::ENABLED, :unauthenticated,    Snippet::PUBLIC,   true],
        [:public, ProjectFeature::ENABLED, :unauthenticated,    Snippet::INTERNAL, false],
        [:public, ProjectFeature::ENABLED, :unauthenticated,    Snippet::PRIVATE,  false],

        [:public, ProjectFeature::ENABLED, :external,           Snippet::PUBLIC,   true],
        [:public, ProjectFeature::ENABLED, :external,           Snippet::INTERNAL, false],
        [:public, ProjectFeature::ENABLED, :external,           Snippet::PRIVATE,  false],

        [:public, ProjectFeature::ENABLED, :non_member,         Snippet::PUBLIC,   true],
        [:public, ProjectFeature::ENABLED, :non_member,         Snippet::INTERNAL, true],
        [:public, ProjectFeature::ENABLED, :non_member,         Snippet::PRIVATE,  false],

        [:public, ProjectFeature::ENABLED, :member,             Snippet::PUBLIC,   true],
        [:public, ProjectFeature::ENABLED, :member,             Snippet::INTERNAL, true],
        [:public, ProjectFeature::ENABLED, :member,             Snippet::PRIVATE,  true],

        [:public, ProjectFeature::ENABLED, :author,             Snippet::PUBLIC,   true],
        [:public, ProjectFeature::ENABLED, :author,             Snippet::INTERNAL, true],
        [:public, ProjectFeature::ENABLED, :author,             Snippet::PRIVATE,  true],

        [:public, ProjectFeature::PRIVATE, :unauthenticated,    Snippet::PUBLIC,   false],
        [:public, ProjectFeature::PRIVATE, :unauthenticated,    Snippet::INTERNAL, false],
        [:public, ProjectFeature::PRIVATE, :unauthenticated,    Snippet::PRIVATE,  false],

        [:public, ProjectFeature::PRIVATE, :external,           Snippet::PUBLIC,   false],
        [:public, ProjectFeature::PRIVATE, :external,           Snippet::INTERNAL, false],
        [:public, ProjectFeature::PRIVATE, :external,           Snippet::PRIVATE,  false],

        [:public, ProjectFeature::PRIVATE, :non_member,         Snippet::PUBLIC,   false],
        [:public, ProjectFeature::PRIVATE, :non_member,         Snippet::INTERNAL, false],
        [:public, ProjectFeature::PRIVATE, :non_member,         Snippet::PRIVATE,  false],

        [:public, ProjectFeature::PRIVATE, :member,             Snippet::PUBLIC,   true],
        [:public, ProjectFeature::PRIVATE, :member,             Snippet::INTERNAL, true],
        [:public, ProjectFeature::PRIVATE, :member,             Snippet::PRIVATE,  true],

        [:public, ProjectFeature::PRIVATE, :author,             Snippet::PUBLIC,   true],
        [:public, ProjectFeature::PRIVATE, :author,             Snippet::INTERNAL, true],
        [:public, ProjectFeature::PRIVATE, :author,             Snippet::PRIVATE,  true],

        [:public, ProjectFeature::DISABLED, :unauthenticated,   Snippet::PUBLIC,   false],
        [:public, ProjectFeature::DISABLED, :unauthenticated,   Snippet::INTERNAL, false],
        [:public, ProjectFeature::DISABLED, :unauthenticated,   Snippet::PRIVATE,  false],

        [:public, ProjectFeature::DISABLED, :external,          Snippet::PUBLIC,   false],
        [:public, ProjectFeature::DISABLED, :external,          Snippet::INTERNAL, false],
        [:public, ProjectFeature::DISABLED, :external,          Snippet::PRIVATE,  false],

        [:public, ProjectFeature::DISABLED, :non_member,        Snippet::PUBLIC,   false],
        [:public, ProjectFeature::DISABLED, :non_member,        Snippet::INTERNAL, false],
        [:public, ProjectFeature::DISABLED, :non_member,        Snippet::PRIVATE,  false],

        [:public, ProjectFeature::DISABLED, :member,            Snippet::PUBLIC,   false],
        [:public, ProjectFeature::DISABLED, :member,            Snippet::INTERNAL, false],
        [:public, ProjectFeature::DISABLED, :member,            Snippet::PRIVATE,  false],

        [:public, ProjectFeature::DISABLED, :author,            Snippet::PUBLIC,   false],
        [:public, ProjectFeature::DISABLED, :author,            Snippet::INTERNAL, false],
        [:public, ProjectFeature::DISABLED, :author,            Snippet::PRIVATE,  false],

        # Internal projects
        [:internal, ProjectFeature::ENABLED, :unauthenticated,  Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::ENABLED, :unauthenticated,  Snippet::INTERNAL, false],
        [:internal, ProjectFeature::ENABLED, :unauthenticated,  Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::ENABLED, :external,         Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::ENABLED, :external,         Snippet::INTERNAL, false],
        [:internal, ProjectFeature::ENABLED, :external,         Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::ENABLED, :non_member,       Snippet::PUBLIC,   true],
        [:internal, ProjectFeature::ENABLED, :non_member,       Snippet::INTERNAL, true],
        [:internal, ProjectFeature::ENABLED, :non_member,       Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::ENABLED, :member,           Snippet::PUBLIC,   true],
        [:internal, ProjectFeature::ENABLED, :member,           Snippet::INTERNAL, true],
        [:internal, ProjectFeature::ENABLED, :member,           Snippet::PRIVATE,  true],

        [:internal, ProjectFeature::ENABLED, :author,           Snippet::PUBLIC,   true],
        [:internal, ProjectFeature::ENABLED, :author,           Snippet::INTERNAL, true],
        [:internal, ProjectFeature::ENABLED, :author,           Snippet::PRIVATE,  true],

        [:internal, ProjectFeature::PRIVATE, :unauthenticated,  Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::PRIVATE, :unauthenticated,  Snippet::INTERNAL, false],
        [:internal, ProjectFeature::PRIVATE, :unauthenticated,  Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::PRIVATE, :external,         Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::PRIVATE, :external,         Snippet::INTERNAL, false],
        [:internal, ProjectFeature::PRIVATE, :external,         Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::PRIVATE, :non_member,       Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::PRIVATE, :non_member,       Snippet::INTERNAL, false],
        [:internal, ProjectFeature::PRIVATE, :non_member,       Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::PRIVATE, :member,           Snippet::PUBLIC,   true],
        [:internal, ProjectFeature::PRIVATE, :member,           Snippet::INTERNAL, true],
        [:internal, ProjectFeature::PRIVATE, :member,           Snippet::PRIVATE,  true],

        [:internal, ProjectFeature::PRIVATE, :author,           Snippet::PUBLIC,   true],
        [:internal, ProjectFeature::PRIVATE, :author,           Snippet::INTERNAL, true],
        [:internal, ProjectFeature::PRIVATE, :author,           Snippet::PRIVATE,  true],

        [:internal, ProjectFeature::DISABLED, :unauthenticated, Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::DISABLED, :unauthenticated, Snippet::INTERNAL, false],
        [:internal, ProjectFeature::DISABLED, :unauthenticated, Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::DISABLED, :external,        Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::DISABLED, :external,        Snippet::INTERNAL, false],
        [:internal, ProjectFeature::DISABLED, :external,        Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::DISABLED, :non_member,      Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::DISABLED, :non_member,      Snippet::INTERNAL, false],
        [:internal, ProjectFeature::DISABLED, :non_member,      Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::DISABLED, :member,          Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::DISABLED, :member,          Snippet::INTERNAL, false],
        [:internal, ProjectFeature::DISABLED, :member,          Snippet::PRIVATE,  false],

        [:internal, ProjectFeature::DISABLED, :author,          Snippet::PUBLIC,   false],
        [:internal, ProjectFeature::DISABLED, :author,          Snippet::INTERNAL, false],
        [:internal, ProjectFeature::DISABLED, :author,          Snippet::PRIVATE,  false],

        # Private projects
        [:private, ProjectFeature::ENABLED, :unauthenticated,   Snippet::PUBLIC,   false],
        [:private, ProjectFeature::ENABLED, :unauthenticated,   Snippet::INTERNAL, false],
        [:private, ProjectFeature::ENABLED, :unauthenticated,   Snippet::PRIVATE,  false],

        [:private, ProjectFeature::ENABLED, :external,          Snippet::PUBLIC,   true],
        [:private, ProjectFeature::ENABLED, :external,          Snippet::INTERNAL, true],
        [:private, ProjectFeature::ENABLED, :external,          Snippet::PRIVATE,  true],

        [:private, ProjectFeature::ENABLED, :non_member,        Snippet::PUBLIC,   false],
        [:private, ProjectFeature::ENABLED, :non_member,        Snippet::INTERNAL, false],
        [:private, ProjectFeature::ENABLED, :non_member,        Snippet::PRIVATE,  false],

        [:private, ProjectFeature::ENABLED, :member,            Snippet::PUBLIC,   true],
        [:private, ProjectFeature::ENABLED, :member,            Snippet::INTERNAL, true],
        [:private, ProjectFeature::ENABLED, :member,            Snippet::PRIVATE,  true],

        [:private, ProjectFeature::ENABLED, :author,            Snippet::PUBLIC,   true],
        [:private, ProjectFeature::ENABLED, :author,            Snippet::INTERNAL, true],
        [:private, ProjectFeature::ENABLED, :author,            Snippet::PRIVATE,  true],

        [:private, ProjectFeature::PRIVATE, :unauthenticated,   Snippet::PUBLIC,   false],
        [:private, ProjectFeature::PRIVATE, :unauthenticated,   Snippet::INTERNAL, false],
        [:private, ProjectFeature::PRIVATE, :unauthenticated,   Snippet::PRIVATE,  false],

        [:private, ProjectFeature::PRIVATE, :external,          Snippet::PUBLIC,   true],
        [:private, ProjectFeature::PRIVATE, :external,          Snippet::INTERNAL, true],
        [:private, ProjectFeature::PRIVATE, :external,          Snippet::PRIVATE,  true],

        [:private, ProjectFeature::PRIVATE, :non_member,        Snippet::PUBLIC,   false],
        [:private, ProjectFeature::PRIVATE, :non_member,        Snippet::INTERNAL, false],
        [:private, ProjectFeature::PRIVATE, :non_member,        Snippet::PRIVATE,  false],

        [:private, ProjectFeature::PRIVATE, :member,            Snippet::PUBLIC,   true],
        [:private, ProjectFeature::PRIVATE, :member,            Snippet::INTERNAL, true],
        [:private, ProjectFeature::PRIVATE, :member,            Snippet::PRIVATE,  true],

        [:private, ProjectFeature::PRIVATE, :author,            Snippet::PUBLIC,   true],
        [:private, ProjectFeature::PRIVATE, :author,            Snippet::INTERNAL, true],
        [:private, ProjectFeature::PRIVATE, :author,            Snippet::PRIVATE,  true],

        [:private, ProjectFeature::DISABLED, :unauthenticated,  Snippet::PUBLIC,   false],
        [:private, ProjectFeature::DISABLED, :unauthenticated,  Snippet::INTERNAL, false],
        [:private, ProjectFeature::DISABLED, :unauthenticated,  Snippet::PRIVATE,  false],

        [:private, ProjectFeature::DISABLED, :external,         Snippet::PUBLIC,   false],
        [:private, ProjectFeature::DISABLED, :external,         Snippet::INTERNAL, false],
        [:private, ProjectFeature::DISABLED, :external,         Snippet::PRIVATE,  false],

        [:private, ProjectFeature::DISABLED, :non_member,       Snippet::PUBLIC,   false],
        [:private, ProjectFeature::DISABLED, :non_member,       Snippet::INTERNAL, false],
        [:private, ProjectFeature::DISABLED, :non_member,       Snippet::PRIVATE,  false],

        [:private, ProjectFeature::DISABLED, :member,           Snippet::PUBLIC,   false],
        [:private, ProjectFeature::DISABLED, :member,           Snippet::INTERNAL, false],
        [:private, ProjectFeature::DISABLED, :member,           Snippet::PRIVATE,  false],

        [:private, ProjectFeature::DISABLED, :author,           Snippet::PUBLIC,   false],
        [:private, ProjectFeature::DISABLED, :author,           Snippet::INTERNAL, false],
        [:private, ProjectFeature::DISABLED, :author,           Snippet::PRIVATE,  false]
      ]
    end

    with_them do
      let!(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel.level_value(project_type.to_s)) }
      let!(:project_feature) { project.project_feature.update_column(:snippets_access_level, feature_visibility) }
      let!(:user) { users[user_type] }
      let!(:snippet) { create(:project_snippet, visibility_level: snippet_type, project: project, author: author) }
      let!(:members) do
        project.add_developer(author)
        project.add_developer(member)
        project.add_developer(external) if project.private?
      end

      context "For #{params[:project_type]} project and #{params[:user_type]} users" do
        it 'agrees with the read_project_snippet policy' do
          expect(can?(user, :read_project_snippet, snippet)).to eq(outcome)
        end

        it 'returns proper outcome' do
          results = described_class.new(user, project: project).execute

          expect(results.include?(snippet)).to eq(outcome)
        end
      end

      context "Without a given project and #{params[:user_type]} users" do
        it 'returns proper outcome' do
          results = described_class.new(user).execute
          expect(results.include?(snippet)).to eq(outcome)
        end

        it 'returns no snippets when the user cannot read cross project' do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

          snippets = described_class.new(user).execute

          expect(snippets).to be_empty
        end
      end
    end
  end

  context 'For personal snippets' do
    let!(:users) do
      {
        unauthenticated: nil,
        external: external,
        non_member: create(:user),
        author: author
      }
    end

    where(:snippet_visibility, :user_type, :outcome) do
      [
        [Snippet::PUBLIC,   :unauthenticated, true],
        [Snippet::PUBLIC,   :external,        true],
        [Snippet::PUBLIC,   :non_member,      true],
        [Snippet::PUBLIC,   :author,          true],

        [Snippet::INTERNAL, :unauthenticated, false],
        [Snippet::INTERNAL, :external,        false],
        [Snippet::INTERNAL, :non_member,      true],
        [Snippet::INTERNAL, :author,          true],

        [Snippet::PRIVATE,  :unauthenticated, false],
        [Snippet::PRIVATE,  :external,        false],
        [Snippet::PRIVATE,  :non_member,      false],
        [Snippet::PRIVATE,  :author,          true]
      ]
    end

    with_them do
      let!(:user) { users[user_type] }
      let!(:snippet) { create(:personal_snippet, visibility_level: snippet_visibility, author: author) }

      context "For personal and #{params[:snippet_visibility]} snippets with #{params[:user_type]} user" do
        it 'agrees with read_personal_snippet policy' do
          expect(can?(user, :read_personal_snippet, snippet)).to eq(outcome)
        end

        it 'returns proper outcome' do
          results = described_class.new(user).execute
          expect(results.include?(snippet)).to eq(outcome)
        end

        it 'returns personal snippets when the user cannot read cross project' do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

          results = described_class.new(user).execute

          expect(results.include?(snippet)).to eq(outcome)
        end
      end
    end
  end
end
