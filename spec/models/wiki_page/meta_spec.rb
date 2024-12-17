# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPage::Meta, feature_category: :wiki do
  let_it_be(:project) { create(:project, :wiki_repo) }
  let_it_be(:other_project) { create(:project) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:slugs) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:notes) }

    it do
      is_expected
        .to have_many(:user_mentions)
        .class_name('Wikis::UserMention')
        .with_foreign_key('wiki_page_meta_id')
        .inverse_of('wiki_page_meta')
    end

    it 'can find slugs' do
      meta = create(:wiki_page_meta)
      slugs = create_list(:wiki_page_slug, 3, wiki_page_meta: meta)

      expect(meta.slugs).to match_array(slugs)
    end
  end

  describe 'Validations' do
    subject do
      described_class.new(title: 'some title', project: project)
    end

    it { is_expected.to validate_length_of(:title).is_at_most(255) }
    it { is_expected.not_to allow_value(nil).for(:title) }

    it 'is forbidden to have two records for the same project with the same canonical_slug' do
      the_slug = generate(:sluggified_title)
      create(:wiki_page_meta, canonical_slug: the_slug, project: project)

      in_violation = build(:wiki_page_meta, canonical_slug: the_slug, project: project)

      expect(in_violation).not_to be_valid
    end

    it 'is forbidden to have both project_id and namespace_id empty' do
      in_violation = build(:wiki_page_meta, namespace: nil, project: nil)

      expect(in_violation).not_to be_valid
    end
  end

  describe '#resource_parent' do
    subject { described_class.new(title: 'some title', project: project) }

    it 'returns container' do
      expect(subject.resource_parent).to eq(project)
    end
  end

  describe '#to_reference' do
    it 'returns a canonical slug as reference to the object' do
      meta = create(:wiki_page_meta, canonical_slug: 'foo')

      expect(meta.to_reference).to eq('foo')
    end
  end

  describe '#canonical_slug' do
    subject { described_class.find(meta.id) }

    let_it_be(:meta) do
      described_class.create!(title: generate(:wiki_page_title), project: project)
    end

    context 'there are no slugs' do
      it { is_expected.to have_attributes(canonical_slug: be_nil) }
    end

    it 'can be set on initialization' do
      meta = create(:wiki_page_meta, canonical_slug: 'foo')

      expect(meta.canonical_slug).to eq('foo')
    end

    context 'we have some non-canonical slugs' do
      before do
        create_list(:wiki_page_slug, 2, wiki_page_meta: subject)
      end

      it { is_expected.to have_attributes(canonical_slug: be_nil) }

      it 'issues at most one query' do
        expect { subject.canonical_slug }.not_to exceed_query_limit(1)
      end

      it 'issues no queries if we already know the slug' do
        subject.canonical_slug

        expect { subject.canonical_slug }.not_to exceed_query_limit(0)
      end
    end

    context 'we have a canonical slug' do
      before do
        create_list(:wiki_page_slug, 2, wiki_page_meta: subject)
      end

      it 'has the correct value' do
        slug = create(:wiki_page_slug, :canonical, wiki_page_meta: subject)

        is_expected.to have_attributes(canonical_slug: slug.slug)
      end
    end

    describe 'canonical_slug=' do
      shared_examples 'canonical_slug setting examples' do
        # Constant overhead of two queries for the transaction
        let(:upper_query_limit) { query_limit + 2 }
        let(:lower_query_limit) { [upper_query_limit - 1, 0].max }
        let(:other_slug) { generate(:sluggified_title) }

        it 'changes it to the correct value' do
          subject.canonical_slug = slug

          expect(subject).to have_attributes(canonical_slug: slug)
        end

        it 'ensures the slug is in the db' do
          subject.canonical_slug = slug

          expect(subject.slugs.canonical.where(slug: slug)).to exist
        end

        it 'issues at most N queries' do
          expect { subject.canonical_slug = slug }.not_to exceed_query_limit(upper_query_limit)
        end

        it 'issues fewer queries if we already know the current slug' do
          subject.canonical_slug = other_slug

          expect { subject.canonical_slug = slug }.not_to exceed_query_limit(lower_query_limit)
        end
      end

      context 'the slug is not known to us' do
        let(:slug) { generate(:sluggified_title) }
        let(:query_limit) { 8 }

        include_examples 'canonical_slug setting examples'
      end

      context 'the slug is already in the DB (but not canonical)' do
        let_it_be(:slug_record) { create(:wiki_page_slug, wiki_page_meta: meta) }

        let(:slug) { slug_record.slug }
        let(:query_limit) { 4 }

        include_examples 'canonical_slug setting examples'
      end

      context 'the slug is already in the DB (and canonical)' do
        let_it_be(:slug_record) { create(:wiki_page_slug, :canonical, wiki_page_meta: meta) }

        let(:slug) { slug_record.slug }
        let(:query_limit) { 4 }

        include_examples 'canonical_slug setting examples'
      end

      context 'the slug is up to date and in the DB' do
        let(:slug) { generate(:sluggified_title) }

        before do
          subject.canonical_slug = slug
        end

        include_examples 'canonical_slug setting examples' do
          let(:other_slug) { slug }
          let(:upper_query_limit) { 0 }
        end
      end
    end
  end

  describe '#wiki_page' do
    let(:wiki_page) { create(:wiki_page, container: project, content: 'test content') }
    let(:meta) { create(:wiki_page_meta, :for_wiki_page, container: project, wiki_page: wiki_page) }

    subject { meta.wiki_page }

    it 'finds the wiki page for the meta record' do
      expect(subject).to eq(wiki_page)
    end
  end

  describe '.find_or_create' do
    let(:old_title)       { generate(:wiki_page_title) }
    let(:last_known_slug) { generate(:sluggified_title) }
    let(:current_slug) { wiki_page.slug }
    let(:title)        { wiki_page.title }
    let(:wiki_page) { create(:wiki_page, project: project) }

    shared_examples 'metadata examples' do
      it 'establishes the correct state', :aggregate_failures do
        create_context

        meta = find_record

        expect(meta).to have_attributes(
          valid?: true,
          canonical_slug: wiki_page.slug,
          title: wiki_page.title,
          container: wiki_page.wiki.container
        )
        expect(meta.updated_at).to eq(wiki_page.version.commit.committed_date)
        expect(meta.created_at).not_to be_after(meta.updated_at)
        expect(meta.slugs.where(slug: last_known_slug)).to exist
        expect(meta.slugs.canonical.where(slug: wiki_page.slug)).to exist
      end

      it 'makes a reasonable number of DB queries' do
        expect(container).to eq(wiki_page.wiki.container)

        expect { find_record }.not_to exceed_query_limit(query_limit)
      end
    end

    include_examples 'creating wiki page meta record examples' do
      let(:container) { project }
      let(:other_container) { other_project }
    end

    context 'no existing record exists' do
      include_examples 'metadata examples' do
        # The base case is 5 queries:
        #  - 2 for the outer transaction
        #  - 1 to find the metadata object if it exists
        #  - 1 to create it if it does not
        #  - 1 to insert last_known_slug and current_slug
        #
        # (Log has been edited for clarity)
        # SAVEPOINT active_record_2
        #
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug IN (?,?)
        #   LIMIT 2
        #
        # INSERT INTO wiki_page_meta (project_id, title) VALUES (?, ?) RETURNING id
        #
        # INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug,canonical)
        #   VALUES (?, ?, ?) (?, ?, ?)
        #   ON CONFLICT  DO NOTHING RETURNING id
        #
        # RELEASE SAVEPOINT active_record_2
        let(:query_limit) { 5 }
        let(:container) { project }
      end
    end

    context 'the commit happened a day ago' do
      before do
        allow(wiki_page.version.commit).to receive(:committed_date).and_return(1.day.ago)
      end

      include_examples 'metadata examples' do
        # Identical to the base case.
        let(:query_limit) { 5 }
        let(:container) { project }
      end
    end

    context 'the last_known_slug is the same as the current slug, as on creation' do
      let(:last_known_slug) { current_slug }

      include_examples 'metadata examples' do
        # Identical to the base case.
        let(:query_limit) { 5 }
        let(:container) { project }
      end
    end

    context 'a record exists in the DB in the correct state' do
      let(:last_known_slug) { current_slug }
      let(:old_title) { title }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # We just need to do the initial query, and the outer transaction
        # SAVEPOINT active_record_2
        #
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 2
        #
        # RELEASE SAVEPOINT active_record_2
        let(:query_limit) { 3 }
        let(:container) { project }
      end
    end

    context 'a record exists in the DB, but we need to update timestamps' do
      let(:last_known_slug) { current_slug }
      let(:old_title) { title }

      before do
        create_previous_version(date: 1.week.ago)
      end

      include_examples 'metadata examples' do
        # We need the query, and the update
        # SAVEPOINT active_record_2
        #
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 2
        #
        # UPDATE wiki_page_meta SET updated_at = ?date WHERE id = ?id
        #
        # RELEASE SAVEPOINT active_record_2
        let(:query_limit) { 4 }
        let(:container) { project }
      end
    end

    context 'we need to update the slug, but not the title' do
      let(:old_title) { title }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Here we need:
        #  - 2 for the outer transaction
        #  - 1 to find the record
        #  - 1 to insert the new slug
        #  - 3 to set canonical state correctly
        #
        # SAVEPOINT active_record_2
        #
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 1
        #
        # INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug,canonical)
        #   VALUES (?, ?, ?) ON CONFLICT  DO NOTHING RETURNING id
        #
        # SELECT * FROM wiki_page_slugs
        #   WHERE wiki_page_slugs.wiki_page_meta_id = ?
        #     AND wiki_page_slugs.slug = ?
        #     LIMIT 1
        # UPDATE wiki_page_slugs SET canonical = FALSE WHERE wiki_page_meta_id = ?
        # UPDATE wiki_page_slugs SET canonical = TRUE WHERE id = ?
        #
        # RELEASE SAVEPOINT active_record_2
        let(:query_limit) { 7 }
        let(:container) { project }
      end
    end

    context 'we need to update the title, but not the slug' do
      let(:last_known_slug) { wiki_page.slug }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Same as minimal case, plus one query to update the title.
        #
        # SAVEPOINT active_record_2
        #
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 1
        #
        # UPDATE wiki_page_meta SET title = ? WHERE id = ?
        #
        # RELEASE SAVEPOINT active_record_2
        let(:query_limit) { 4 }
        let(:container) { project }
      end
    end

    context 'we want to change the slug back to a previous version' do
      let(:slug_1) { generate(:sluggified_title) }
      let(:slug_2) { generate(:sluggified_title) }

      let(:wiki_page) { create(:wiki_page, title: slug_1, project: project) }
      let(:last_known_slug) { slug_2 }

      before do
        meta = create_previous_version(title: title, slug: slug_1)
        meta.canonical_slug = slug_2
      end

      include_examples 'metadata examples' do
        let(:query_limit) { 7 }
        let(:container) { project }
      end
    end

    context 'we want to change the slug a bunch of times' do
      let(:slugs) { generate_list(:sluggified_title, 3) }

      before do
        meta = create_previous_version
        slugs.each { |slug| meta.canonical_slug = slug }
      end

      include_examples 'metadata examples' do
        let(:query_limit) { 7 }
        let(:container) { project }
      end
    end

    context 'we need to update the title and the slug' do
      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # -- outer transaction
        # SAVEPOINT active_record_2
        #
        # -- to find the record
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug IN (?,?)
        #   LIMIT 2
        #
        # -- to update the title
        # UPDATE wiki_page_meta SET title = ? WHERE id = ?
        #
        # -- to update slug
        # INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug,canonical)
        #   VALUES (?, ?, ?) ON CONFLICT  DO NOTHING RETURNING id
        #
        # UPDATE wiki_page_slugs SET canonical = FALSE WHERE wiki_page_meta_id = ?
        #
        # SELECT * FROM wiki_page_slugs
        #   WHERE wiki_page_slugs.wiki_page_meta_id = ?
        #     AND wiki_page_slugs.slug = ?
        #     LIMIT 1
        #
        # UPDATE wiki_page_slugs SET canonical = TRUE WHERE id = ?
        #
        # RELEASE SAVEPOINT active_record_2
        let(:query_limit) { 8 }
        let(:container) { project }
      end
    end
  end
end
