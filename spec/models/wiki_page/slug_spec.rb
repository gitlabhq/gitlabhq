# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPage::Slug, feature_category: :wiki do
  let_it_be(:meta) { create(:wiki_page_meta) }

  describe 'Associations' do
    it { is_expected.to belong_to(:wiki_page_meta) }

    it 'refers correctly to the wiki_page_meta' do
      created = create(:wiki_page_slug, wiki_page_meta: meta)

      expect(created.reload.wiki_page_meta).to eq(meta)
    end
  end

  describe 'scopes' do
    describe 'canonical' do
      subject { described_class.canonical }

      context 'there are no slugs' do
        it { is_expected.to be_empty }
      end

      context 'there are some non-canonical slugs' do
        before do
          create(:wiki_page_slug)
        end

        it { is_expected.to be_empty }
      end

      context 'there is at least one canonical slugs' do
        before do
          create(:wiki_page_slug, :canonical)
        end

        it { is_expected.not_to be_empty }
      end
    end
  end

  describe 'Validations' do
    let(:canonical) { false }

    subject do
      build(:wiki_page_slug, canonical: canonical, wiki_page_meta: meta)
    end

    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:wiki_page_meta_id) }
    it { is_expected.to validate_length_of(:slug).is_at_most(2048) }
    it { is_expected.not_to allow_value(nil).for(:slug) }

    describe 'only_one_slug_can_be_canonical_per_meta_record' do
      context 'there are no other slugs' do
        it { is_expected.to be_valid }

        context 'the current slug is canonical' do
          let(:canonical) { true }

          it { is_expected.to be_valid }
        end
      end

      context 'there are other slugs, but they are not canonical' do
        before do
          create(:wiki_page_slug, wiki_page_meta: meta)
        end

        it { is_expected.to be_valid }

        context 'the current slug is canonical' do
          let(:canonical) { true }

          it { is_expected.to be_valid }
        end
      end

      context 'there is already a canonical slug' do
        before do
          create(:wiki_page_slug, canonical: true, wiki_page_meta: meta)
        end

        it { is_expected.to be_valid }

        context 'the current slug is canonical' do
          let(:canonical) { true }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end
end
