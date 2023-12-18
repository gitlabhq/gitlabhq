# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Tag, type: :model, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:package) { create(:npm_package, version: '1.0.2', project: project, updated_at: 3.days.ago) }

  describe '#ensure_project_id' do
    it 'sets the project_id before saving' do
      tag = build(:packages_tag)
      expect(tag.project_id).to be_nil
      tag.save!
      expect(tag.project_id).not_to be_nil
      expect(tag.project_id).to eq(tag.package.project_id)
    end

    it 'does not override the project_id if set' do
      another_project = create(:project)
      tag = build(:packages_tag, project_id: another_project.id)
      tag.save!
      expect(tag.project_id).to eq(another_project.id)
    end
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:package).inverse_of(:tags) }
  end

  describe 'validations' do
    subject { create(:packages_tag) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '.for_package_ids' do
    let(:package2) { create(:package, project: project, updated_at: 2.days.ago) }
    let(:package3) { create(:package, project: project, updated_at: 1.day.ago) }
    let!(:tag1) { create(:packages_tag, package: package) }
    let!(:tag2) { create(:packages_tag, package: package2) }
    let!(:tag3) { create(:packages_tag, package: package3) }

    subject { described_class.for_package_ids(project.packages) }

    it { is_expected.to match_array([tag1, tag2, tag3]) }

    context 'with too many tags' do
      before do
        stub_const('Packages::Tag::FOR_PACKAGES_TAGS_LIMIT', 2)
      end

      it { is_expected.to match_array([tag2, tag3]) }
    end

    context 'with package ids' do
      subject { described_class.for_package_ids(project.packages.select(:id)) }

      it { is_expected.to match_array([tag1, tag2, tag3]) }
    end
  end

  describe '.with_name' do
    let_it_be(:package) { create(:package) }
    let_it_be(:tag1) { create(:packages_tag, package: package, name: 'tag1') }
    let_it_be(:tag2) { create(:packages_tag, package: package, name: 'tag2') }
    let_it_be(:tag3) { create(:packages_tag, package: package, name: 'tag3') }

    let(:name) { 'tag1' }

    subject { described_class.with_name(name) }

    it { is_expected.to contain_exactly(tag1) }

    context 'with nil name' do
      let(:name) { nil }

      it { is_expected.to eq([]) }
    end

    context 'with multiple names' do
      let(:name) { %w[tag1 tag3] }

      it { is_expected.to contain_exactly(tag1, tag3) }
    end
  end

  describe '.for_package_ids_with_distinct_names' do
    let_it_be(:package2) { create(:package, project: project) }
    let_it_be(:package3) { create(:package, project: project) }
    let_it_be(:tag1) { create(:packages_tag, name: 'latest', package: package, updated_at: 4.days.ago) }
    let_it_be(:tag2) { create(:packages_tag, name: 'latest', package: package2, updated_at: 3.days.ago) }
    let_it_be(:tag3) { create(:packages_tag, name: 'latest', package: package2, updated_at: 2.days.ago) }
    let_it_be(:tag4) { create(:packages_tag, name: 'tag4', package: package3, updated_at: 5.days.ago) }
    let_it_be(:tag5) { create(:packages_tag, name: 'tag5', package: package3, updated_at: 4.days.ago) }
    let_it_be(:tag6) { create(:packages_tag, name: 'tag6', package: package3, updated_at: 6.days.ago) }

    subject { described_class.for_package_ids_with_distinct_names(project.packages) }

    before do
      stub_const("#{described_class}::FOR_PACKAGES_TAGS_LIMIT", 3)
    end

    # `tag3` is returned because it's the most recently updated with the name `latest`.
    # `tag5` is returned before `tag4` because it was updated more recently than `tag4`.
    it { is_expected.to eq([tag3, tag5, tag4]) }
  end
end
