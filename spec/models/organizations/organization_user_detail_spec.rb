# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUserDetail, type: :model, feature_category: :cell do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:organization_user_details).required }
    it { is_expected.to belong_to(:user).inverse_of(:organization_user_details).required }
  end

  describe 'validations' do
    subject { build(:organization_user_detail) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:display_name) }
    it { is_expected.to validate_uniqueness_of(:username).scoped_to(:organization_id) }

    describe '#no_namespace_conflicts' do
      subject(:organization_user_detail) do
        build(:organization_user_detail, username: username, organization: organization)
      end

      let_it_be(:organization) { create(:organization) }
      let_it_be(:other_organization) { create(:organization) }

      let(:username) { 'capybara' }

      it { is_expected.to be_valid }

      context 'when a User exists in the same organization with the same username' do
        let!(:user) { create(:user, :with_namespace, username: username, organization: organization) }

        it 'adds a validation error on username' do
          expect(organization_user_detail).not_to be_valid
          expect(organization_user_detail.errors[:username]).to include('has already been taken')
        end

        context 'when the user is the same as the OrganizationUserDetail' do
          subject(:organization_user_detail) do
            build(:organization_user_detail, user: user, username: username, organization: organization)
          end

          it { is_expected.to be_valid }
        end
      end

      context 'when a User exists in another organization with the same username' do
        let!(:user) { create(:user, :with_namespace, username: username, organization: other_organization) }

        it { is_expected.to be_valid }
      end

      context 'when a group exists in the same organization with a path equal to the username' do
        let!(:group) { create(:group, path: username, organization: organization) }

        it 'adds a validation error on username' do
          expect(organization_user_detail).not_to be_valid
          expect(organization_user_detail.errors[:username]).to include('has already been taken')
        end
      end

      context 'when a group exists in another organization with a path equal to the username' do
        let!(:group) { create(:group, path: username, organization: other_organization) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'scopes' do
    let_it_be(:organization_user_detail) { create(:organization_user_detail) }

    describe '.for_references' do
      it 'includes related records' do
        instance = nil

        ActiveRecord::QueryRecorder.new(skip_cached: false) do
          instance = described_class.for_references.where(id: organization_user_detail.id).first
        end

        experiment = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          expect(instance.user).to be_a(User)
          expect(instance.organization).to be_a(Organizations::Organization)
        end

        expect(experiment.count).to eq(0)
      end
    end

    describe '.for_organization' do
      it 'scopes query to organization' do
        expect(described_class.for_organization(organization_user_detail.organization).count).to eq(1)
        expect(described_class.for_organization(99999).count).to eq(0)
      end
    end

    describe '.with_usernames' do
      it 'locates all users within argument' do
        username = organization_user_detail.username
        expect(described_class.with_usernames('fakeusername', username).count).to eq(1)
      end

      it 'matches usernames case-insensitively' do
        username = organization_user_detail.username
        expect(described_class.with_usernames('fakeusername', username.upcase).count).to eq(1)
      end

      it 'returns none when no arguments / nil arguments passed' do
        expect(described_class.with_usernames.count).to eq(0)
        expect(described_class.with_usernames(nil).count).to eq(0)
      end
    end

    describe 'Referable methods' do
      describe 'reference_prefix' do
        subject(:reference_prefix) { described_class.new.reference_prefix }

        it { is_expected.to eq('@') }
      end

      describe 'reference_pattern' do
        subject(:reference_pattern) { described_class.new.reference_pattern }

        it 'matches @username patterns' do
          expect(reference_pattern).to be_a(Regexp)

          expect(reference_pattern.match?('@username')).to be true
          expect(reference_pattern.match?('@user.name')).to be true
          expect(reference_pattern.match?('@user-name')).to be true
          expect(reference_pattern.match?('@-name')).to be false
          expect(reference_pattern.match?('user@name')).to be false
        end
      end

      describe 'to_reference' do
        subject(:to_reference) { described_class.new(username: username).to_reference }

        let(:username) { 'test_user_name' }

        it { is_expected.to eq('@test_user_name') }
      end
    end
  end
end
