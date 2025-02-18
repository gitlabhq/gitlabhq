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

    context 'when a conflicting meta record exists' do
      let!(:older_meta) do
        create(:wiki_page_meta, container: container, canonical_slug: current_slug, created_at: 1.day.ago)
      end

      let!(:newer_meta) { create(:wiki_page_meta, container: container, canonical_slug: 'foobar') }
      let!(:todo) { create(:todo, target: newer_meta) }

      before do
        slug = newer_meta.slugs.first
        slug[:slug] = current_slug
        slug.save!
      end

      it 'finds the older record' do
        expect(find_record).to eq(older_meta)
      end

      it 'destroys the newer record' do
        expect { find_record }.to change { WikiPage::Meta.count }.by(-1)
      end

      it 'moves associated todos to the older record' do
        expect { find_record }.to change { todo.reload.target }.from(newer_meta).to(older_meta)
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
