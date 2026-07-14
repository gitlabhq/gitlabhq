# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MarkdownCache::ActiveRecord::Extension, feature_category: :wiki do
  let_it_be(:project) { create(:project) }

  let(:klass) do
    type_id = build(:work_item_system_defined_type, :issue).id
    Class.new(ActiveRecord::Base) do
      self.table_name = 'issues'
      include CacheMarkdownField
      cache_markdown_field :title, whitelisted: true
      cache_markdown_field :description, pipeline: :single_line

      attribute :author
      attribute :project

      before_validation -> { self.work_item_type_id = type_id }
    end
  end

  let(:cache_version) { Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION_SHIFTED }
  let(:thing) do
    klass.create!(
      project_id: project.id, namespace_id: project.project_namespace_id,
      title: markdown, title_html: html, cached_markdown_version: cache_version
    )
  end

  let(:markdown) { '`Foo`' }
  let(:html) { '<p dir="auto"><code>Foo</code></p>' }

  let(:updated_markdown) { '`Bar`' }
  let(:updated_html) { '<p dir="auto"><code>Bar</code></p>' }

  let(:rollout_flag) { :"markdown_cache_stochastic_rollout_#{Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION}" }

  # Build a persisted row with a chosen cached_markdown_version without
  # going through the before_create callback, which would overwrite it
  # based on the current roll of the rollout flag.
  def persisted_row_at_version(version)
    row = klass.create!(
      project_id: project.id, namespace_id: project.project_namespace_id,
      title: markdown, title_html: html
    )
    row.update_columns(cached_markdown_version: version)
    row.reload
  end

  before do
    stub_commonmark_sourcepos_disabled
  end

  # Asserts what the version_upgrade_counter records for a given action. Call
  # sites provide `perform_upgrade` (the action under test) and, when an
  # increment is expected, `upgrade_row` (the row whose class labels the metric).
  # Pass `expected_kind: nil` to assert no increment at all.
  shared_examples 'a version upgrade count' do |expected_kind:|
    it "records #{expected_kind ? "a #{expected_kind} upgrade" : 'no upgrade'}" do
      counter = instance_double(Prometheus::Client::Counter, increment: nil)
      allow(Gitlab::MarkdownCache).to receive(:version_upgrade_counter).and_return(counter)

      perform_upgrade

      if expected_kind
        expect(counter).to have_received(:increment).with(class: upgrade_row.class.name, kind: expected_kind)
      else
        expect(counter).not_to have_received(:increment)
      end
    end
  end

  context 'an unchanged markdown field' do
    let(:thing) { klass.new(project_id: project.id, namespace_id: project.project_namespace_id, title: markdown) }

    before do
      thing.title = thing.title # rubocop:disable Lint/SelfAssignment -- testing unchanged field behavior
      thing.save!
    end

    it { expect(thing.title).to eq(markdown) }
    it { expect(thing.title_html).to eq(html) }
    it { expect(thing.title_html_changed?).not_to be_truthy }
    it { expect(thing.cached_markdown_version).to eq(cache_version) }
  end

  context 'a changed markdown field' do
    let(:thing) do
      klass.create!(
        project_id: project.id, namespace_id: project.project_namespace_id,
        title: markdown, title_html: html, cached_markdown_version: cache_version
      )
    end

    before do
      thing.title = updated_markdown
      thing.save!
    end

    it { expect(thing.title_html).to eq(updated_html) }
    it { expect(thing.cached_markdown_version).to eq(cache_version) }
  end

  context 'when a markdown field is set repeatedly to an empty string' do
    it do
      expect(thing).to receive(:refresh_markdown_cache).once
      thing.title = ''
      thing.save!
      thing.title = ''
      thing.save!
    end
  end

  context 'when a markdown field is set repeatedly to a string which renders as empty html' do
    it do
      expect(thing).to receive(:refresh_markdown_cache).once
      thing.title = '[//]: # (This is also a comment.)'
      thing.save!
      thing.title = '[//]: # (This is also a comment.)'
      thing.save!
    end
  end

  context 'a non-markdown field changed' do
    let(:thing) do
      klass.new(
        project_id: project.id, namespace_id: project.project_namespace_id, title: markdown,
        title_html: html, cached_markdown_version: cache_version
      )
    end

    before do
      thing.state_id = 2
      thing.save!
    end

    it { expect(thing.state_id).to eq(2) }
    it { expect(thing.title).to eq(markdown) }
    it { expect(thing.title_html).to eq(html) }
    it { expect(thing.cached_markdown_version).to eq(cache_version) }
  end

  context 'version is out of date' do
    let(:thing) do
      klass.new(
        project_id: project.id, namespace_id: project.project_namespace_id,
        title: updated_markdown, title_html: html, cached_markdown_version: nil
      )
    end

    before do
      thing.save!
    end

    it { expect(thing.title_html).to eq(updated_html) }
    it { expect(thing.cached_markdown_version).to eq(cache_version) }
  end

  context 'when an invalidating field is changed' do
    it 'invalidates the cache when project changes' do
      thing.project = :new_project
      allow(Banzai::Renderer).to receive(:cacheless_render_field).and_return(updated_html)

      thing.save!

      expect(thing.title_html).to eq(updated_html)
      expect(thing.description_html).to eq(updated_html)
      expect(thing.cached_markdown_version).to eq(cache_version)
    end

    it 'invalidates the cache when author changes' do
      thing.author = :new_author
      allow(Banzai::Renderer).to receive(:cacheless_render_field).and_return(updated_html)

      thing.save!

      expect(thing.title_html).to eq(updated_html)
      expect(thing.description_html).to eq(updated_html)
      expect(thing.cached_markdown_version).to eq(cache_version)
    end
  end

  describe '.attributes' do
    it 'excludes cache attributes that are denylisted by default' do
      expect(thing.attributes.keys.sort).not_to include(%w[description_html])
    end
  end

  describe '#cached_html_up_to_date?' do
    let(:thing) do
      klass.create!(
        project_id: project.id, namespace_id: project.project_namespace_id,
        title: updated_markdown, title_html: html, cached_markdown_version: nil
      )
    end

    subject { thing.cached_html_up_to_date?(:title) }

    it 'returns false if markdown has been changed but html has not' do
      thing.title = "changed!"

      is_expected.to be_falsy
    end

    it 'returns true if markdown has not been changed but html has' do
      thing.title_html = updated_html

      is_expected.to be_truthy
    end

    it 'returns true if markdown and html have both been changed' do
      thing.title = updated_markdown
      thing.title_html = updated_html

      is_expected.to be_truthy
    end

    it 'returns false if the markdown field is set but the html is not' do
      thing.title_html = nil

      is_expected.to be_falsy
    end
  end

  describe '#refresh_markdown_cache!' do
    before do
      thing.title = updated_markdown
    end

    it 'skips saving if not persisted' do
      expect(thing).to receive(:persisted?).and_return(false)
      expect(thing).not_to receive(:update_columns)

      thing.refresh_markdown_cache!
    end

    it 'saves the changes' do
      expect(thing).to receive(:persisted?).and_return(true)

      expect(thing).to receive(:update_columns)
                         .with({ "title_html" => updated_html,
                                 "description_html" => "",
                                 "cached_markdown_version" => cache_version })

      thing.refresh_markdown_cache!
    end
  end

  context 'with note' do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'notes'
        include CacheMarkdownField
        include Importable
        include Mentionable

        attr_mentionable :note, pipeline: :note
        cache_markdown_field :note, pipeline: :note
      end
    end

    let(:thing) { klass.new(note: markdown, project_id: project.id) }

    before do
      thing.note = "hello world"
      thing.noteable_type = "Issue"
    end

    it 'calls store_mentions!' do
      expect(thing).to receive(:store_mentions!).and_call_original

      thing.save!
    end

    context 'during import' do
      before do
        thing.importing = true
      end

      it 'does not call store_mentions!' do
        expect(thing).not_to receive(:store_mentions!)

        thing.save!
      end
    end
  end

  context 'when persisted cache is newer than current version' do
    before do
      thing.update_column(:cached_markdown_version, thing.cached_markdown_version + 1)
    end

    it 'does not regress the cached_markdown_version' do
      thing.refresh_markdown_cache!
      thing.reload

      expect(thing.cached_markdown_version).to eq((Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION << 16) + 1)
    end
  end

  context 'when persisted cache is nil' do
    before do
      thing.update_column(:cached_markdown_version, nil)
    end

    it 'does not save the generated HTML' do
      expect(thing).to receive(:update_columns)

      thing.refresh_markdown_cache!
    end

    # A persisted row with a nil version is a rare anomaly (legacy/imported/
    # backfilled) rather than the rollout's target population, so its catch-up
    # is counted as a backfill upgrade.
    context 'for the version upgrade counter' do
      let(:upgrade_row) { thing }
      let(:perform_upgrade) { thing.refresh_markdown_cache! }

      it_behaves_like 'a version upgrade count', expected_kind: :backfill
    end
  end

  describe 'stochastic version rollout' do
    let(:previous_cache_version) { (Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION - 1) << 16 }

    # Simulate a rollout in progress by setting CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED
    # to the version we're rolling from.
    before do
      stub_const(
        'Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED',
        previous_cache_version
      )
      stub_feature_flags(rollout_flag => false)
    end

    context 'when the rollout flag is disabled' do
      it 'treats rows at the previous shifted version as up-to-date' do
        row = persisted_row_at_version(previous_cache_version)

        expect(row.cached_html_up_to_date?(:title)).to be(true)
      end

      it 'persists newly written rows at the current shifted version regardless of the roll' do
        row = klass.new(project_id: project.id, namespace_id: project.project_namespace_id, title: markdown)
        row.save!

        expect(row.cached_markdown_version).to eq(cache_version)
      end

      it 'upgrades a row at the previous version through a content edit (writes go to current)' do
        row = persisted_row_at_version(previous_cache_version)

        row.update!(title: updated_markdown)
        row.reload

        expect(row.cached_markdown_version).to eq(cache_version)
        expect(row.title_html).to eq(updated_html)
      end

      it 'does not rewrite rows at the current shifted version backwards via save_markdown' do
        row = persisted_row_at_version(cache_version)

        row.refresh_markdown_cache!
        row.reload

        expect(row.cached_markdown_version).to eq(cache_version)
      end

      it 'does not regress rows at the current shifted version on a normal save (before_update path)' do
        row = persisted_row_at_version(cache_version)

        row.update!(updated_at: Time.current + 1.second)
        row.reload

        expect(row.cached_markdown_version).to eq(cache_version)
      end
    end

    context 'when the rollout flag is at 100%' do
      before do
        stub_feature_flags(rollout_flag => true)
      end

      it 'considers rows at the previous shifted version stale' do
        row = persisted_row_at_version(previous_cache_version)

        expect(row.cached_html_up_to_date?(:title)).to be(false)
      end

      it 'rewrites a stale row to the current shifted version on a render_field read' do
        row = persisted_row_at_version(previous_cache_version)

        Banzai::Renderer.render_field(row, :title)
        row.reload

        expect(row.cached_markdown_version).to eq(cache_version)
      end

      it 'persists newly written rows at the current shifted version' do
        row = klass.new(project_id: project.id, namespace_id: project.project_namespace_id, title: markdown)
        row.save!

        expect(row.cached_markdown_version).to eq(cache_version)
      end

      context 'when rewriting a row at the previous version' do
        let(:upgrade_row) { persisted_row_at_version(previous_cache_version) }
        let(:perform_upgrade) { Banzai::Renderer.render_field(upgrade_row, :title) }

        it_behaves_like 'a version upgrade count', expected_kind: :rollout
      end

      context 'when rewriting a row older than the previous version' do
        let(:older_version) { (Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION - 2) << 16 }
        let(:upgrade_row) { persisted_row_at_version(older_version) }
        let(:perform_upgrade) { Banzai::Renderer.render_field(upgrade_row, :title) }

        it_behaves_like 'a version upgrade count', expected_kind: :backfill
      end
    end

    context 'counter is not incremented when the version is not advancing' do
      context 'for a row already at the current version under a "previous" roll' do
        let(:perform_upgrade) { Banzai::Renderer.render_field(persisted_row_at_version(cache_version), :title) }

        it_behaves_like 'a version upgrade count', expected_kind: nil
      end

      context 'for a same-version resync write' do
        let(:perform_upgrade) { persisted_row_at_version(cache_version).refresh_markdown_cache! }

        it_behaves_like 'a version upgrade count', expected_kind: nil
      end

      context 'when creating a new record' do
        let(:perform_upgrade) do
          klass.create!(project_id: project.id, namespace_id: project.project_namespace_id, title: markdown)
        end

        it_behaves_like 'a version upgrade count', expected_kind: nil
      end
    end
  end

  describe 'steady state (no rollout in progress)' do
    let(:older_version) { (Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION - 1) << 16 }

    before do
      stub_const('Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED', nil)
    end

    it 'treats older versions as stale' do
      row = persisted_row_at_version(older_version)

      expect(row.cached_html_up_to_date?(:title)).to be(false)
    end

    it 'rewrites older versions to the current shifted version on a render_field read' do
      row = persisted_row_at_version(older_version)

      Banzai::Renderer.render_field(row, :title)
      row.reload

      expect(row.cached_markdown_version).to eq(cache_version)
    end

    # With no rollout active there is no "previous" version, so every upgrade is
    # a backfill of a straggler row (the background we observe between rollouts).
    context 'for the version upgrade counter' do
      let(:upgrade_row) { persisted_row_at_version(older_version) }
      let(:perform_upgrade) { Banzai::Renderer.render_field(upgrade_row, :title) }

      it_behaves_like 'a version upgrade count', expected_kind: :backfill
    end
  end
end
