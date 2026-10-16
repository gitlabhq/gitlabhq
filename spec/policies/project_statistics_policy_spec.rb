# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectStatisticsPolicy, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  describe '#rules' do
    let_it_be(:external)   { create(:user, :external) }
    let_it_be(:guest)      { create(:user) }
    let_it_be(:reporter)   { create(:user) }
    let_it_be(:developer)  { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:non_member) { create(:user) }

    let_it_be_with_refind(:public_project) { create(:project, :public) }
    let_it_be_with_refind(:private_project) { create(:project, :private) }
    let_it_be_with_refind(:internal_project) { create(:project, :internal) }

    let(:users) do
      {
        unauthenticated: nil,
        non_member: non_member,
        guest: guest,
        reporter: reporter,
        developer: developer,
        maintainer: maintainer
      }
    end

    before_all do
      [public_project, private_project, internal_project].each do |project|
        create(:project_statistics, project: project)
        project.add_guest(guest)
        project.add_reporter(reporter)
        project.add_developer(developer)
        project.add_maintainer(maintainer)
      end
    end

    where(:project_type, :user_type, :outcome) do
      [
        # Public projects
        [:public, :unauthenticated, false],
        [:public, :non_member, false],
        [:public, :guest, false],
        [:public, :reporter, true],
        [:public, :developer, true],
        [:public, :maintainer, true],

        # Private project
        [:private, :unauthenticated, false],
        [:private, :non_member, false],
        [:private, :guest, false],
        [:private, :reporter, true],
        [:private, :developer, true],
        [:private, :maintainer, true],

        # Internal projects
        [:internal, :unauthenticated, false],
        [:internal, :non_member, false],
        [:internal, :guest, false],
        [:internal, :reporter, true],
        [:internal, :developer, true],
        [:internal, :maintainer, true]
      ]
    end

    with_them do
      let(:user) { users[user_type] }
      let(:project) { public_send(:"#{project_type}_project") }
      let(:project_statistics) { project.statistics }

      subject { Ability.allowed?(user, :read_statistics, project_statistics) }

      it { is_expected.to eq(outcome) }

      context 'when the user is external' do
        let(:user) { external }

        before do
          unless [:unauthenticated, :non_member].include?(user_type)
            project.add_member(external, user_type)
          end
        end

        it { is_expected.to eq(outcome) }
      end
    end
  end
end
