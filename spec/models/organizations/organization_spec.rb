# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Organization, type: :model, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:default_organization) { create(:organization, :default) }

  describe 'associations' do
    it { is_expected.to have_one(:organization_detail).inverse_of(:organization).autosave(true) }

    it { is_expected.to have_many :namespaces }
    it { is_expected.to have_many :groups }
    it { is_expected.to have_many(:users).through(:organization_users).inverse_of(:organizations) }
    it { is_expected.to have_many(:organization_users).inverse_of(:organization) }
    it { is_expected.to have_many :projects }
  end

  describe 'validations' do
    subject { create(:organization) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_length_of(:path).is_at_least(2).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:path).case_insensitive }

    describe 'path validator' do
      using RSpec::Parameterized::TableSyntax

      let(:default_path_error) do
        "can contain only letters, digits, '_', '-' and '.'. Cannot start with '-' or end in '.', '.git' or '.atom'."
      end

      let(:reserved_path_error) do
        "is a reserved name"
      end

      where(:path, :valid, :error_message) do
        'path.'           | false  | ref(:default_path_error)
        'path.git'        | false  | ref(:default_path_error)
        'new'             | false  | ref(:reserved_path_error)
        '.path'           | true   | nil
        'org__path'       | true   | nil
        'some-name'       | true   | nil
        'simple'          | true   | nil
      end

      with_them do
        it 'validates organization path' do
          organization = build(:organization, name: 'Default', path: path)

          expect(organization.valid?).to be(valid)
          expect(organization.errors.full_messages.to_sentence).to include(error_message) if error_message.present?
        end
      end
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:description).to(:organization_detail) }
    it { is_expected.to delegate_method(:description_html).to(:organization_detail) }
    it { is_expected.to delegate_method(:avatar).to(:organization_detail) }
    it { is_expected.to delegate_method(:avatar_url).to(:organization_detail) }
    it { is_expected.to delegate_method(:remove_avatar!).to(:organization_detail) }
  end

  describe 'nested attributes' do
    it { is_expected.to accept_nested_attributes_for(:organization_detail) }
    it { is_expected.to accept_nested_attributes_for(:organization_users) }
  end

  context 'when using scopes' do
    describe '.without_default' do
      it 'excludes default organization' do
        expect(described_class.without_default).not_to include(default_organization)
      end

      it 'includes other organizations organization' do
        expect(described_class.without_default).to include(organization)
      end
    end
  end

  describe '.default_organization' do
    it 'returns the default organization' do
      expect(described_class.default_organization).to eq(default_organization)
    end
  end

  describe '.default?' do
    context 'when organization is default' do
      it 'returns true' do
        expect(described_class.default?(default_organization.id)).to eq(true)
      end
    end

    context 'when organization is not default' do
      it 'returns false' do
        expect(described_class.default?(organization.id)).to eq(false)
      end
    end
  end

  describe '#id' do
    context 'when organization is default' do
      it 'has id 1' do
        expect(default_organization.id).to eq(1)
      end
    end

    context 'when organization is not default' do
      it 'does not have id 1' do
        expect(organization.id).not_to eq(1)
      end
    end
  end

  describe '#visibility_level_field' do
    it { expect(organization.visibility_level_field).to eq(:visibility_level) }
  end

  describe '#visibility_level' do
    subject { organization.visibility_level }

    context 'with default' do
      it { is_expected.to eq(Gitlab::VisibilityLevel::PRIVATE) }
    end

    context 'with visibility possibilities' do
      using RSpec::Parameterized::TableSyntax

      where(:attribute_name, :value, :result) do
        :visibility        | 'public'                         | Gitlab::VisibilityLevel::PUBLIC
        :visibility_level  | Gitlab::VisibilityLevel::PUBLIC  | Gitlab::VisibilityLevel::PUBLIC
        'visibility'       | 'public'                         | Gitlab::VisibilityLevel::PUBLIC
        'visibility_level' | Gitlab::VisibilityLevel::PUBLIC  | Gitlab::VisibilityLevel::PUBLIC
        :visibility        | 'private'                        | Gitlab::VisibilityLevel::PRIVATE
        :visibility_level  | Gitlab::VisibilityLevel::PRIVATE | Gitlab::VisibilityLevel::PRIVATE
        'visibility'       | 'private'                        | Gitlab::VisibilityLevel::PRIVATE
        'visibility_level' | Gitlab::VisibilityLevel::PRIVATE | Gitlab::VisibilityLevel::PRIVATE
        :visibility_level  | 12345                            | Gitlab::VisibilityLevel::PRIVATE
        :visibility_level  | 'bogus'                          | Gitlab::VisibilityLevel::PRIVATE
      end

      with_them do
        it 'sets the visibility level' do
          org = described_class.new(attribute_name => value)

          expect(org.visibility_level).to eq(result)
        end
      end
    end
  end

  describe '#destroy!' do
    context 'when trying to delete the default organization' do
      it 'raises an error' do
        expect do
          default_organization.destroy!
        end.to raise_error(ActiveRecord::RecordNotDestroyed, _('Cannot delete the default organization'))
      end
    end

    context 'when trying to delete a non-default organization' do
      let(:to_be_removed) { create(:organization) }

      it 'does not raise error' do
        expect { to_be_removed.destroy! }.not_to raise_error
      end
    end
  end

  describe '#destroy' do
    context 'when trying to delete the default organization' do
      it 'returns false' do
        expect(default_organization.destroy).to eq(false)
      end
    end

    context 'when trying to delete a non-default organization' do
      let(:to_be_removed) { create(:organization) }

      it 'returns true' do
        expect(to_be_removed.destroy).to eq(to_be_removed)
      end
    end
  end

  describe '#organization_detail' do
    it 'ensures organization has organization_detail upon initialization' do
      expect(organization.organization_detail).to be_present
      expect(organization.organization_detail).not_to be_persisted
    end
  end

  describe '#default?' do
    context 'when organization is default' do
      it 'returns true' do
        expect(default_organization.default?).to eq(true)
      end
    end

    context 'when organization is not default' do
      it 'returns false' do
        expect(organization.default?).to eq(false)
      end
    end
  end

  describe '#name' do
    context 'when organization is default' do
      it 'returns Default' do
        expect(default_organization.name).to eq('Default')
      end
    end
  end

  describe '#to_param' do
    let_it_be(:organization) { build(:organization, path: 'org_path') }

    it 'returns the path' do
      expect(organization.to_param).to eq('org_path')
    end
  end

  context 'on deleting organizations via SQL' do
    it 'does not allow to delete default organization' do
      expect { default_organization.delete }.to raise_error(
        ActiveRecord::StatementInvalid, /Deletion of the default Organization is not allowed/
      )
    end

    it 'allows to delete any other organization' do
      organization.delete

      expect(described_class.where(id: organization)).not_to exist
    end
  end

  describe '#user?' do
    let_it_be(:user) { create :user }

    subject { organization.user?(user) }

    context 'when user is an organization user' do
      before do
        create :organization_user, organization: organization, user: user
      end

      it { is_expected.to eq true }
    end

    context 'when user is not an organization user' do
      it { is_expected.to eq false }
    end
  end

  describe '#owner?' do
    let_it_be(:user) { create(:user) }

    subject { organization.owner?(user) }

    context 'when user is an owner' do
      before do
        create(:organization_user, :owner, organization: organization, user: user)
      end

      it { is_expected.to eq true }
    end

    context 'when user is not an owner' do
      before do
        create(:organization_user, organization: organization, user: user)
      end

      it { is_expected.to eq false }
    end

    context 'when user is not an organization user' do
      it { is_expected.to eq false }
    end
  end

  describe '#web_url' do
    it 'returns web url from `Gitlab::UrlBuilder`' do
      web_url = 'http://127.0.0.1:3000/-/organizations/default'

      expect(Gitlab::UrlBuilder).to receive(:build).with(organization, only_path: nil).and_return(web_url)
      expect(organization.web_url).to eq(web_url)
    end
  end

  describe '.search' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.search(query) }

    context 'when searching by name' do
      where(:query, :expected_organizations) do
        'Organization' | [ref(:organization)]
        'default'      | [ref(:default_organization)]
      end

      with_them do
        it { is_expected.to contain_exactly(*expected_organizations) }
      end
    end

    context 'when searching by path' do
      where(:query, :expected_organizations) do
        'organization' | [ref(:organization)]
        'default'      | [ref(:default_organization)]
      end

      with_them do
        it { is_expected.to contain_exactly(*expected_organizations) }
      end
    end
  end
end
