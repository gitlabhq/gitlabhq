# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::DesignAtVersion do
  include DesignManagementTestHelpers

  let_it_be(:issue, reload: true) { create(:issue) }
  let_it_be(:issue_b, reload: true) { create(:issue) }
  let_it_be(:design, reload: true) { create(:design, issue: issue) }
  let_it_be(:version) { create(:design_version, designs: [design]) }

  describe '#id' do
    subject { described_class.new(design: design, version: version) }

    it 'combines design.id and version.id' do
      expect(subject.id).to include(design.id.to_s, version.id.to_s)
    end
  end

  describe '#==' do
    it 'identifies objects created with the same parameters as equal' do
      design = build_stubbed(:design, issue: issue)
      version = build_stubbed(:design_version, designs: [design], issue: issue)

      this = build_stubbed(:design_at_version, design: design, version: version)
      other = build_stubbed(:design_at_version, design: design, version: version)

      expect(this).to eq(other)
      expect(other).to eq(this)
    end

    it 'identifies unequal objects as unequal, by virtue of their version' do
      design = build_stubbed(:design, issue: issue)
      version_a = build_stubbed(:design_version, designs: [design])
      version_b = build_stubbed(:design_version, designs: [design])

      this = build_stubbed(:design_at_version, design: design, version: version_a)
      other = build_stubbed(:design_at_version, design: design, version: version_b)

      expect(this).not_to eq(nil)
      expect(this).not_to eq(design)
      expect(this).not_to eq(other)
      expect(other).not_to eq(this)
    end

    it 'identifies unequal objects as unequal, by virtue of their design' do
      design_a = build_stubbed(:design, issue: issue)
      design_b = build_stubbed(:design, issue: issue)
      version = build_stubbed(:design_version, designs: [design_a, design_b])

      this = build_stubbed(:design_at_version, design: design_a, version: version)
      other = build_stubbed(:design_at_version, design: design_b, version: version)

      expect(this).not_to eq(other)
      expect(other).not_to eq(this)
    end

    it 'rejects objects with the same id and the wrong class' do
      dav = build_stubbed(:design_at_version)

      expect(dav).not_to eq(double('id', id: dav.id))
    end

    it 'expects objects to be of the same type, not subtypes' do
      subtype = Class.new(described_class)
      dav = build_stubbed(:design_at_version)
      other = subtype.new(design: dav.design, version: dav.version)

      expect(dav).not_to eq(other)
    end
  end

  describe 'status methods' do
    let_it_be(:design_a) { create(:design, issue: issue) }
    let_it_be(:design_b) { create(:design, issue: issue) }

    let_it_be(:version_a)   { create(:design_version, designs: [design_a]) }
    let_it_be(:version_b)   { create(:design_version, designs: [design_b]) }
    let_it_be(:version_mod) { create(:design_version, modified_designs: [design_a, design_b]) }
    let_it_be(:version_c)   { create(:design_version, deleted_designs: [design_a]) }
    let_it_be(:version_d)   { create(:design_version, deleted_designs: [design_b]) }
    let_it_be(:version_e)   { create(:design_version, designs: [design_a]) }

    describe 'a design before it has been created' do
      subject { build(:design_at_version, design: design_b, version: version_a) }

      it 'is not deleted' do
        expect(subject).not_to be_deleted
      end

      it 'has the status :not_created_yet' do
        expect(subject).to have_attributes(status: :not_created_yet)
      end
    end

    describe 'a design as of its creation' do
      subject { build(:design_at_version, design: design_a, version: version_a) }

      it 'is not deleted' do
        expect(subject).not_to be_deleted
      end

      it 'has the status :current' do
        expect(subject).to have_attributes(status: :current)
      end
    end

    describe 'a design after it has been created, but before deletion' do
      subject { build(:design_at_version, design: design_b, version: version_c) }

      it 'is not deleted' do
        expect(subject).not_to be_deleted
      end

      it 'has the status :current' do
        expect(subject).to have_attributes(status: :current)
      end
    end

    describe 'a design as of its modification' do
      subject { build(:design_at_version, design: design_a, version: version_mod) }

      it 'is not deleted' do
        expect(subject).not_to be_deleted
      end

      it 'has the status :current' do
        expect(subject).to have_attributes(status: :current)
      end
    end

    describe 'a design as of its deletion' do
      subject { build(:design_at_version, design: design_a, version: version_c) }

      it 'is deleted' do
        expect(subject).to be_deleted
      end

      it 'has the status :deleted' do
        expect(subject).to have_attributes(status: :deleted)
      end
    end

    describe 'a design after its deletion' do
      subject { build(:design_at_version, design: design_b, version: version_e) }

      it 'is deleted' do
        expect(subject).to be_deleted
      end

      it 'has the status :deleted' do
        expect(subject).to have_attributes(status: :deleted)
      end
    end

    describe 'a design on its recreation' do
      subject { build(:design_at_version, design: design_a, version: version_e) }

      it 'is not deleted' do
        expect(subject).not_to be_deleted
      end

      it 'has the status :current' do
        expect(subject).to have_attributes(status: :current)
      end
    end
  end

  describe 'validations' do
    subject(:design_at_version) { build_stubbed(:design_at_version) }

    it { is_expected.to be_valid }

    describe 'a design-at-version without a design' do
      subject { described_class.new(design: nil, version: build(:design_version)) }

      it { is_expected.to be_invalid }

      it 'mentions the design in the errors' do
        subject.valid?

        expect(subject.errors[:design]).to be_present
      end
    end

    describe 'a design-at-version without a version' do
      subject { described_class.new(design: build(:design), version: nil) }

      it { is_expected.to be_invalid }

      it 'mentions the version in the errors' do
        subject.valid?

        expect(subject.errors[:version]).to be_present
      end
    end

    describe 'design_and_version_belong_to_the_same_issue' do
      context 'both design and version are supplied' do
        subject(:design_at_version) { build(:design_at_version, design: design, version: version) }

        context 'the design belongs to the same issue as the version' do
          it { is_expected.to be_valid }
        end

        context 'the design does not belong to the same issue as the version' do
          let(:design) { create(:design) }
          let(:version) { create(:design_version) }

          it { is_expected.to be_invalid }
        end
      end

      context 'the factory is just supplied with a design' do
        let(:design) { create(:design) }

        subject(:design_at_version) { build(:design_at_version, design: design) }

        it { is_expected.to be_valid }
      end

      context 'the factory is just supplied with a version' do
        let(:version) { create(:design_version) }

        subject(:design_at_version) { build(:design_at_version, version: version) }

        it { is_expected.to be_valid }
      end
    end

    describe 'design_and_version_have_issue_id' do
      subject(:design_at_version) { build(:design_at_version, design: design, version: version) }

      context 'the design has no issue_id, because it is being imported' do
        let(:design) { create(:design, :importing) }

        it { is_expected.to be_invalid }
      end

      context 'the version has no issue_id, because it is being imported' do
        let(:version) { create(:design_version, :importing) }

        it { is_expected.to be_invalid }
      end

      context 'both the design and the version are being imported' do
        let(:version) { create(:design_version, :importing) }
        let(:design) { create(:design, :importing) }

        it { is_expected.to be_invalid }
      end
    end
  end

  def id_of(design, version)
    build(:design_at_version, design: design, version: version).id
  end

  describe '.lazy_find' do
    let!(:version_a) do
      create(:design_version, designs: create_list(:design, 3, issue: issue))
    end

    let!(:version_b) do
      create(:design_version, designs: create_list(:design, 1, issue: issue))
    end

    let!(:version_c) do
      create(:design_version, designs: create_list(:design, 1, issue: issue_b))
    end

    let(:id_a)   { id_of(version_a.designs.first,  version_a) }
    let(:id_b)   { id_of(version_a.designs.second, version_a) }
    let(:id_c)   { id_of(version_a.designs.last,   version_a) }
    let(:id_d)   { id_of(version_b.designs.first,  version_b) }
    let(:id_e)   { id_of(version_c.designs.first,  version_c) }
    let(:bad_id) { id_of(version_c.designs.first,  version_a) }

    def find(the_id)
      described_class.lazy_find(the_id)
    end

    let(:db_calls) { 2 }

    it 'issues fewer queries than the naive approach would' do
      expect do
        dav_a = find(id_a)
        dav_b = find(id_b)
        dav_c = find(id_c)
        dav_d = find(id_d)
        dav_e = find(id_e)
        should_not_exist = find(bad_id)

        expect(dav_a.version).to eq(version_a)
        expect(dav_b.version).to eq(version_a)
        expect(dav_c.version).to eq(version_a)
        expect(dav_d.version).to eq(version_b)
        expect(dav_e.version).to eq(version_c)
        expect(should_not_exist).not_to be_present

        expect(version_a.designs).to include(dav_a.design, dav_b.design, dav_c.design)
        expect(version_b.designs).to include(dav_d.design)
        expect(version_c.designs).to include(dav_e.design)
      end.not_to exceed_query_limit(db_calls)
    end
  end

  describe '.find' do
    let(:results) { described_class.find(ids) }

    # 2 versions, with 5 total designs on issue A, so 2*5 = 10
    let!(:version_a) do
      create(:design_version, designs: create_list(:design, 3, issue: issue))
    end

    let!(:version_b) do
      create(:design_version, designs: create_list(:design, 2, issue: issue))
    end
    # 1 version, with 3 designs on issue B, so 1*3 = 3

    let!(:version_c) do
      create(:design_version, designs: create_list(:design, 3, issue: issue_b))
    end

    context 'invalid ids' do
      let(:ids) do
        version_b.designs.map { |d| id_of(d, version_c) }
      end

      describe '#count' do
        it 'counts 0 records' do
          expect(results.count).to eq(0)
        end
      end

      describe '#empty?' do
        it 'is empty' do
          expect(results).to be_empty
        end
      end

      describe '#to_a' do
        it 'finds no records' do
          expect(results.to_a).to eq([])
        end
      end
    end

    context 'valid ids' do
      let(:red_herrings) { issue_b.designs.sample(2).map { |d| id_of(d, version_a) } }

      let(:ids) do
        a_ids = issue.designs.sample(2).map { |d| id_of(d, version_a) }
        b_ids = issue.designs.sample(2).map { |d| id_of(d, version_b) }
        c_ids = issue_b.designs.sample(2).map { |d| id_of(d, version_c) }

        a_ids + b_ids + c_ids + red_herrings
      end

      before do
        ids.size # force IDs
      end

      describe '#count' do
        it 'counts 2 records' do
          expect(results.count).to eq(6)
        end

        it 'issues at most two queries' do
          expect { results.count }.not_to exceed_query_limit(2)
        end
      end

      describe '#to_a' do
        it 'finds 6 records' do
          expect(results.size).to eq(6)
          expect(results).to all(be_a(described_class))
        end

        it 'only returns records with matching IDs' do
          expect(results.map(&:id)).to match_array(ids - red_herrings)
        end

        it 'only returns valid records' do
          expect(results).to all(be_valid)
        end

        it 'issues at most two queries' do
          expect { results.to_a }.not_to exceed_query_limit(2)
        end
      end
    end
  end
end
