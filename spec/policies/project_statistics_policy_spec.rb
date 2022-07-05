# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectStatisticsPolicy do
  using RSpec::Parameterized::TableSyntax

  describe '#rules' do
    let(:external)   { create(:user, :external) }
    let(:guest)      { create(:user) }
    let(:reporter)   { create(:user) }
    let(:developer)  { create(:user) }
    let(:maintainer) { create(:user) }

    let(:users) do
      {
        unauthenticated: nil,
        non_member: create(:user),
        guest: guest,
        reporter: reporter,
        developer: developer,
        maintainer: maintainer
      }
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
      let(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel.level_value(project_type.to_s)) }
      let(:project_statistics) { create(:project_statistics, project: project) }

      subject { Ability.allowed?(user, :read_statistics, project_statistics) }

      before do
        project.add_guest(guest)
        project.add_reporter(reporter)
        project.add_developer(developer)
        project.add_maintainer(maintainer)
      end

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
