# frozen_string_literal: true

RSpec.shared_examples 'creating wiki page meta record examples' do
  let(:old_title)       { generate(:wiki_page_title) }
  let(:last_known_slug) { generate(:sluggified_title) }
  let(:current_slug)    { wiki_page.slug }
  let(:title)           { wiki_page.title }
  let(:wiki_page)       { create(:wiki_page, container: container) }

  def find_record
    described_class.find_or_create(last_known_slug, wiki_page)
  end

  def create_previous_version(
    title: old_title, slug: last_known_slug,
    date: wiki_page.version.commit.committed_date)
    create(
      :wiki_page_meta,
      title: title, container: container,
      created_at: date, updated_at: date,
      canonical_slug: slug
    )
  end

  def create_context
    # Ensure that we behave nicely with respect to other containers
    # We have:
    #  - page in other container with same canonical_slug
    create(:wiki_page_meta, container: other_container, canonical_slug: wiki_page.slug)

    #  - page in same container with different canonical_slug, but with
    #    an old slug that = canonical_slug
    different_slug = generate(:sluggified_title)
    create(:wiki_page_meta, container: container, canonical_slug: different_slug)
      .slugs.create!(slug: wiki_page.slug)
  end

  describe 'when there are problems' do
    context 'when the slug is too long' do
      let(:last_known_slug) { FFaker::Lorem.characters(2050) }

      it 'raises an error' do
        expect { find_record }.to raise_error ActiveRecord::ValueTooLong
      end
    end

    context 'when a conflicting record exists' do
      before do
        create(:wiki_page_meta, container: container, canonical_slug: last_known_slug)
        create(:wiki_page_meta, container: container, canonical_slug: current_slug)
      end

      it 'raises an error' do
        expect { find_record }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when the wiki page is not valid' do
      let(:wiki_page) { build(:wiki_page, container: container, title: nil) }

      it 'raises an error' do
        expect { find_record }.to raise_error(described_class::WikiPageInvalid)
      end
    end
  end

  describe '#readable_by?' do
    let(:meta) { create(:wiki_page_meta, container: container, canonical_slug: current_slug) }
    let_it_be(:user) { create(:user) }

    subject { meta.readable_by?(user) }

    context 'when user is a member' do
      before do
        container.add_developer(user)
      end

      it { is_expected.to be true }
    end

    context 'when user is not a member' do
      it { is_expected.to be false }
    end
  end
end
