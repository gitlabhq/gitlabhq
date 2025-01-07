# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKey, :mailer, feature_category: :continuous_delivery do
  describe "Associations" do
    it { is_expected.to have_many(:deploy_keys_projects) }

    it do
      is_expected.to have_many(:deploy_keys_projects_with_write_access)
        .conditions(can_push: true)
        .class_name('DeployKeysProject')
        .inverse_of(:deploy_key)
    end

    it do
      is_expected.to have_many(:projects_with_write_access)
        .class_name('Project')
        .through(:deploy_keys_projects_with_write_access)
        .source(:project)
    end

    it do
      is_expected.to have_many(:deploy_keys_projects_with_readonly_access)
        .conditions(can_push: false)
        .class_name('DeployKeysProject')
        .inverse_of(:deploy_key)
    end

    it do
      is_expected.to have_many(:projects_with_readonly_access)
        .class_name('Project')
        .through(:deploy_keys_projects_with_readonly_access)
        .source(:project)
    end

    it { is_expected.to have_many(:projects) }
    it { is_expected.to have_many(:protected_branch_push_access_levels).inverse_of(:deploy_key) }
    it { is_expected.to have_many(:protected_tag_create_access_levels).inverse_of(:deploy_key) }
  end

  describe 'notification' do
    let(:user) { create(:user) }

    it 'does not send a notification' do
      perform_enqueued_jobs do
        create(:deploy_key, user: user)
      end

      should_not_email(user)
    end
  end

  describe '#user' do
    let(:deploy_key) { create(:deploy_key) }
    let(:user) { create(:user) }

    context 'when user is set' do
      before do
        deploy_key.user = user
      end

      it 'returns the user' do
        expect(deploy_key.user).to be(user)
      end
    end

    context 'when user is not set' do
      it 'returns the ghost user' do
        expect(deploy_key.user).to eq(Users::Internal.ghost)
      end
    end
  end

  describe '.with_write_access_for_project' do
    let_it_be(:project) { create(:project, :private) }

    subject { described_class.with_write_access_for_project(project) }

    context 'when no project is passed in' do
      let(:project) { nil }

      it { is_expected.to be_empty }
    end

    context 'when a project is passed in' do
      let_it_be(:deploy_keys_project) { create(:deploy_keys_project, :write_access, project: project) }
      let_it_be(:deploy_key) { deploy_keys_project.deploy_key }

      it 'only returns deploy keys with write access' do
        create(:deploy_keys_project, project: project)

        is_expected.to contain_exactly(deploy_key)
      end

      it 'returns deploy keys only for this project' do
        other_project = create(:project)
        create(:deploy_keys_project, :write_access, project: other_project)

        is_expected.to contain_exactly(deploy_key)
      end

      context 'and a specific deploy key is passed in' do
        subject { described_class.with_write_access_for_project(project, deploy_key: specific_deploy_key) }

        context 'and this deploy key is not linked to the project' do
          let(:specific_deploy_key) { create(:deploy_key) }

          it { is_expected.to be_empty }
        end

        context 'and this deploy key has no write access to the project' do
          let(:specific_deploy_key) { create(:deploy_key, deploy_keys_projects: [create(:deploy_keys_project, project: project)]) }

          it { is_expected.to be_empty }
        end

        context 'and this deploy key has write access to the project' do
          let(:specific_deploy_key) { create(:deploy_key, deploy_keys_projects: [create(:deploy_keys_project, :write_access, project: project)]) }

          it { is_expected.to contain_exactly(specific_deploy_key) }
        end
      end
    end
  end

  describe 'PolicyActor methods' do
    let_it_be(:user) { create(:user) }
    let_it_be(:deploy_key) { create(:deploy_key, user: user) }
    let_it_be(:project) { create(:project, creator: user, namespace: user.namespace) }

    let(:methods) { PolicyActor.instance_methods }

    subject { deploy_key }

    it 'responds to all PolicyActor methods' do
      methods.each do |method|
        expect(subject.respond_to?(method)).to be true
      end
    end

    describe '#can?' do
      it { expect(user.can?(:read_project, project)).to be true }

      context 'when a read deploy key is enabled in the project' do
        let!(:deploy_keys_project) { create(:deploy_keys_project, project: project, deploy_key: deploy_key) }

        it { expect(subject.can?(:read_project, project)).to be false }
        it { expect(subject.can?(:download_code, project)).to be true }
        it { expect(subject.can?(:push_code, project)).to be false }
      end

      context 'when a write deploy key is enabled in the project' do
        let!(:deploy_keys_project) { create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key) }

        it { expect(subject.can?(:read_project, project)).to be false }
        it { expect(subject.can?(:download_code, project)).to be true }
        it { expect(subject.can?(:push_code, project)).to be true }
      end

      context 'when the deploy key is not enabled in the project' do
        it { expect(subject.can?(:read_project, project)).to be false }
        it { expect(subject.can?(:download_code, project)).to be false }
        it { expect(subject.can?(:push_code, project)).to be false }
      end
    end
  end

  describe '#audit_details' do
    it "equals to the key's title" do
      expect(subject.audit_details).to eq(subject.title)
    end
  end

  describe 'search' do
    let!(:deploy_key1) { create(:deploy_key, title: 'Production key') }
    let!(:deploy_key2) { create(:deploy_key, title: 'Staging key') }
    let!(:deploy_key3) { create(:deploy_key, title: 'Development key') }

    describe '.search_by_title' do
      it 'returns deploy keys with matching titles' do
        expect(described_class.search_by_title('production')).to contain_exactly(deploy_key1)
        expect(described_class.search_by_title('key')).to contain_exactly(deploy_key1, deploy_key2, deploy_key3)
      end

      it 'is case-insensitive' do
        expect(described_class.search_by_title('PRODUCTION')).to contain_exactly(deploy_key1)
      end
    end

    describe '.search_by_key' do
      it 'returns deploy keys with matching sha' do
        key = deploy_key1.fingerprint_sha256
        expect(described_class.search_by_key(key)).to contain_exactly(deploy_key1)
      end
    end

    describe '.search' do
      context 'when searching by title' do
        it 'returns deploy keys with matching titles' do
          expect(described_class.search('production', 'title')).to contain_exactly(deploy_key1)
        end
      end

      context 'when searching by key' do
        it 'returns deploy keys with matching sha' do
          key = deploy_key2.fingerprint_sha256
          expect(described_class.search(key, 'key')).to contain_exactly(deploy_key2)
        end
      end

      context 'when searching without specifying a field' do
        it 'returns deploy keys matching either title or sha' do
          key = deploy_key3.fingerprint_sha256
          expect(described_class.search('Development')).to contain_exactly(deploy_key3)
          expect(described_class.search(key)).to contain_exactly(deploy_key3)
        end
      end

      context 'when search term is blank' do
        it 'returns all deploy keys' do
          expect(described_class.search('')).to contain_exactly(deploy_key1, deploy_key2, deploy_key3)
        end
      end
    end
  end
end
