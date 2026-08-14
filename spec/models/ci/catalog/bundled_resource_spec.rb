# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::BundledResource, feature_category: :pipeline_composition do
  describe 'associations' do
    it { is_expected.to have_many(:versions).class_name('Ci::Catalog::BundledResources::Version') }
    it { is_expected.to have_many(:components).class_name('Ci::Catalog::BundledResources::Component') }
  end

  describe 'validations' do
    subject { build(:ci_catalog_bundled_resource) }

    it { is_expected.to validate_presence_of(:server_fqdn) }
    it { is_expected.to validate_presence_of(:full_path) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:server_fqdn).is_at_most(255) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:full_path).is_at_most(1024) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_uniqueness_of(:full_path).scoped_to(:server_fqdn).case_insensitive }
  end

  describe 'natural key normalization' do
    it 'downcases server_fqdn and full_path' do
      resource = create(:ci_catalog_bundled_resource,
        server_fqdn: 'GitLab.com', full_path: 'GitLab-Org/Components/Foo')

      expect(resource.server_fqdn).to eq('gitlab.com')
      expect(resource.full_path).to eq('gitlab-org/components/foo')
    end

    it 'rejects a resource differing only by case in server_fqdn or full_path' do
      create(:ci_catalog_bundled_resource, server_fqdn: 'gitlab.com', full_path: 'gitlab-org/components/foo')

      expect do
        create(:ci_catalog_bundled_resource, server_fqdn: 'GitLab.com', full_path: 'GitLab-Org/Components/Foo')
      end.to raise_error(ActiveRecord::RecordInvalid, /Full path has already been taken/)
    end

    it 'downcases the natural key on a write that skips validations' do
      described_class.insert_all([{
        server_fqdn: 'GitLab.com',
        full_path: 'GitLab-Org/Components/Foo',
        name: 'foo',
        created_at: Time.current,
        updated_at: Time.current
      }])

      expect(described_class.last).to have_attributes(
        server_fqdn: 'gitlab.com',
        full_path: 'gitlab-org/components/foo'
      )
    end

    it 'rejects a mixed-case natural key inserted by raw SQL' do
      expect do
        described_class.connection.execute(<<~SQL)
          INSERT INTO catalog_bundled_resources (server_fqdn, full_path, name, created_at, updated_at)
          VALUES ('GitLab.com', 'GitLab-Org/Components/Foo', 'foo', NOW(), NOW())
        SQL
      end.to raise_error(ActiveRecord::StatementInvalid, /check_catalog_bundled_resources/)
    end
  end
end
