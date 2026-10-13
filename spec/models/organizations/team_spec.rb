# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Team, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:teams).required }
  end

  describe 'validations' do
    subject { build(:organization_team) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_length_of(:path).is_at_least(2).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(2048) }

    describe 'path format' do
      # The character rules themselves are covered by spec/lib/gitlab/path_regex_spec.rb;
      # here we only assert the model validates against Gitlab::PathRegex and reports its message.
      it 'validates the path against the namespace format regex' do
        team = build(:organization_team, path: 'team a')

        expect(team).to be_invalid
        expect(team.errors[:path]).to include(Gitlab::PathRegex.namespace_format_message)
      end

      it 'does not reject a path that is a reserved top-level route word' do
        expect(build(:organization_team, path: 'admin')).to be_valid
      end
    end

    describe 'organization-scoped uniqueness' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:other_organization) { create(:organization) }

      before do
        create(:organization_team, organization: organization, name: 'Platform', path: 'platform')
      end

      where(:field, :value) do
        [
          [:name, 'Platform'],
          [:path, 'platform']
        ]
      end

      with_them do
        it 'rejects a duplicate in the same organization' do
          team = build(:organization_team, organization: organization, field => value)

          expect(team).to be_invalid
          expect(team.errors[field]).to include('has already been taken')
        end

        it 'rejects a case variant in the same organization' do
          team = build(:organization_team, organization: organization, field => value.swapcase)

          expect(team).to be_invalid
          expect(team.errors[field]).to include('has already been taken')
        end

        it 'allows the same value in a different organization' do
          team = build(:organization_team, organization: other_organization, field => value)

          expect(team).to be_valid
        end
      end

      it 'rejects a duplicate that differs only by surrounding whitespace' do
        team = build(:organization_team, organization: organization, name: '  Platform  ', path: '  platform  ')

        expect(team).to be_invalid
        expect(team.errors[:name]).to include('has already been taken')
        expect(team.errors[:path]).to include('has already been taken')
      end
    end
  end

  describe 'scopes' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:other_team) { create(:organization_team, name: 'zeta') }
    let_it_be(:team_b) { create(:organization_team, organization: organization, name: 'beta') }
    let_it_be(:team_a) { create(:organization_team, organization: organization, name: 'alpha') }

    describe '.in_organization' do
      it 'returns only teams in the organization' do
        expect(described_class.in_organization(organization)).to contain_exactly(team_a, team_b)
      end
    end

    describe '.order_by_name' do
      it 'orders teams by name' do
        expect(described_class.in_organization(organization).order_by_name).to eq([team_a, team_b])
      end
    end
  end

  describe '.search' do
    let_it_be(:team) { create(:organization_team, name: 'Platform Engineering', path: 'platform-eng') }
    let_it_be(:other_team) { create(:organization_team, name: 'Design', path: 'design') }

    it 'matches on name' do
      expect(described_class.search('Engineering')).to contain_exactly(team)
    end

    it 'matches on path' do
      expect(described_class.search('platform-eng')).to contain_exactly(team)
    end

    it 'returns nothing when neither matches' do
      expect(described_class.search('nonexistent')).to be_empty
    end
  end

  describe 'deleting the organization' do
    it 'deletes its teams through the cascading foreign key' do
      # A second organization is required: an organization refuses to be destroyed when it is the last one.
      create(:organization)
      organization = create(:organization)
      create(:organization_team, organization: organization)

      expect { organization.destroy! }.to change { described_class.count }.by(-1)
    end
  end
end
