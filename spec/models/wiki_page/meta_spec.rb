# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPage::Meta, feature_category: :wiki do
  let_it_be(:project) { create(:project, :wiki_repo) }
  let_it_be(:other_project) { create(:project) }

  describe '.for_projects_visible_to_user' do
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }
    let_it_be(:private_meta) { create(:wiki_page_meta, title: 'Private Page', project: private_project) }
    let_it_be(:public_meta) { create(:wiki_page_meta, title: 'Public Page', project: public_project) }

    subject(:results) { described_class.for_projects_visible_to_user(user) }

    it 'excludes meta records from the private project' do
      expect(results).to include(public_meta)
      expect(results).not_to include(private_meta)
    end

    context 'when user has access to the private project' do
      before_all do
        private_project.add_developer(user)
      end

      it 'returns meta records for both private and public projects' do
        expect(results).to include(private_meta, public_meta)
      end
    end
  end

  describe '.for_groups_visible_to_user' do
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }
    let_it_be(:public_meta) do
      create(:wiki_page_meta, title: 'Public Group Page', namespace: public_group)
    end

    let_it_be(:private_group) { create(:group, :private) }
    let_it_be(:private_meta) do
      create(:wiki_page_meta, title: 'Private Group Page', namespace: private_group)
    end

    subject(:results) { described_class.for_groups_visible_to_user(user) }

    it 'excludes meta records from the private group' do
      expect(results).to include(public_meta)
      expect(results).not_to include(private_meta)
    end

    context 'when user has access to the private group' do
      before_all do
        private_group.add_developer(user)
      end

      it 'returns meta records for both private and public groups' do
        expect(results).to include(private_meta, public_meta)
      end
    end

    context 'when meta record belongs to a project' do
      let!(:project_meta) { create(:wiki_page_meta, title: 'Project Page', project: create(:project, :public)) }

      it 'excludes project-level wiki page meta records' do
        expect(results).to include(public_meta)
        expect(results).not_to include(project_meta)
      end
    end
  end

  describe '.active' do
    let_it_be(:active_meta) { create(:wiki_page_meta, title: 'Active Page', project: project) }
    let_it_be(:deleted_meta) do
      create(:wiki_page_meta, title: 'Deleted Page', project: project, deleted_at: 3.days.ago)
    end

    it 'returns only records without deleted_at set' do
      results = described_class.active

      expect(results).to include(active_meta)
      expect(results).not_to include(deleted_meta)
    end
  end

  describe '.search_by_title' do
    let_it_be(:meta_1) { create(:wiki_page_meta, title: 'Deploy Guide', project: project) }
    let_it_be(:meta_2) { create(:wiki_page_meta, title: 'Setup Instructions', project: project) }
    let_it_be(:meta_3) { create(:wiki_page_meta, title: 'Deployment Pipeline', project: project) }

    it 'returns records matching the search term case-insensitively' do
      results = described_class.search_by_title('deploy')

      expect(results).to include(meta_1, meta_3)
      expect(results).not_to include(meta_2)
    end

    it 'returns records matching partial titles' do
      results = described_class.search_by_title('Guide')

      expect(results).to include(meta_1)
      expect(results).not_to include(meta_2, meta_3)
    end

    it 'is case-insensitive' do
      results = described_class.search_by_title('SETUP')

      expect(results).to include(meta_2)
      expect(results).not_to include(meta_1, meta_3)
    end
  end

  describe '.id_in_ordered' do
    let_it_be(:meta_a) { create(:wiki_page_meta, title: 'Page A', project: project) }
    let_it_be(:meta_b) { create(:wiki_page_meta, title: 'Page B', project: project) }
    let_it_be(:meta_c) { create(:wiki_page_meta, title: 'Page C', project: project) }

    it 'returns records in the specified order' do
      ordered_ids = [meta_c.id, meta_a.id, meta_b.id]
      results = described_class.id_in_ordered(ordered_ids)

      expect(results.map(&:id)).to eq(ordered_ids)
    end

    it 'returns records matching the given ids' do
      results = described_class.id_in_ordered([meta_a.id, meta_b.id])

      expect(results).to contain_exactly(meta_a, meta_b)
    end

    it 'handles a single id' do
      results = described_class.id_in_ordered([meta_a.id])

      expect(results).to contain_exactly(meta_a)
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:slugs) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:todos) }
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
      meta = create(:wiki_page_meta, :for_wiki_page)

      expect(meta.to_reference).to eq("[wiki_page:#{meta.container.full_path}:#{meta.wiki_page.slug}]")
    end
  end

  describe '#gfm_reference' do
    it 'returns class name with canonical slug as reference to the object' do
      meta = create(:wiki_page_meta, :for_wiki_page, container: project)

      expect(meta.gfm_reference)
        .to eq("project wiki page [wiki_page:#{meta.container.full_path}:#{meta.wiki_page.slug}]")
    end
  end

  describe '#participants' do
    let_it_be(:wiki_page_meta) { create(:wiki_page_meta, canonical_slug: 'foo', container: project) }
    let_it_be(:user_1) { create(:user, developer_of: project) }
    let_it_be(:user_2) { create(:user, developer_of: project) }
    let_it_be(:user_3) { create(:user, developer_of: project) }
    let_it_be(:note_1) { create(:note, project: project, noteable: wiki_page_meta, author: user_1, note: "Quux") }
    let_it_be(:note_2) { create(:note, project: project, noteable: wiki_page_meta, author: user_2, note: "Quuux") }

    it 'returns all note authors' do
      expect(wiki_page_meta.participants).to match_array([user_1, user_2])
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
