# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'tmpdir'
require 'fileutils'
require_relative '../../scripts/update_whats_new_content'
require_relative '../support/silence_stdout'

RSpec.describe UpdateWhatsNewContent, :silence_output, feature_category: :tooling do
  subject(:updater) do
    described_class.new(
      whats_new_template_path: template_path,
      today: today,
      force: force
    )
  end

  let(:template_path) do
    File.join(described_class::ROOT, 'data', 'whats_new', 'templates', 'YYYYMMDD0001_XX_YY.yml')
  end

  # 19.2 release day release week. Overridden per context in #current_release.
  let(:today) { Date.new(2026, 7, 16) }

  let(:force) { false }

  let(:feature_doc) do
    <<~MD
      ---
      title: Test Feature
      tier: [ Ultimate ]
      offering: [ gitlab_com, self_managed ]
      stage: software_supply_chain_security
      documentation_link: "../../../test/test.md"
      level: primary
      ---

      GitLab 19.2 introduces auto-remediation.
    MD
  end

  let(:state) { {} }
  let(:feature_path) { state.fetch(:feature_path) }

  around do |example|
    Tempfile.create(['feature', '.md']) do |file|
      file.write(feature_doc)
      file.flush
      state[:feature_path] = file.path

      example.run
    end
  end

  describe '#extract_frontmatter' do
    it 'returns the parsed frontmatter and the body separately' do
      metadata, body = updater.send(:extract_frontmatter, feature_path)

      expect(metadata).to include(
        'title' => 'Test Feature',
        'tier' => ['Ultimate'],
        'offering' => %w[gitlab_com self_managed],
        'stage' => 'software_supply_chain_security',
        'level' => 'primary'
      )
      expect(body).to eq("GitLab 19.2 introduces auto-remediation.\n")
    end

    it 'returns an empty hash and the whole file when there is no frontmatter' do
      Tempfile.create(['plain', '.md']) do |file|
        file.write("no frontmatter here\n")
        file.flush

        metadata, body = updater.send(:extract_frontmatter, file.path)

        expect(metadata).to eq({})
        expect(body).to eq("no frontmatter here\n")
      end
    end
  end

  describe '#build_whats_new_entry' do
    let(:release_date) { [{ 'version' => '19.2', 'date' => '2026-07-16' }] }

    let(:feature) do
      metadata, body = updater.send(:extract_frontmatter, feature_path)
      UpdateWhatsNewContent::Feature.new(feature_path, metadata, body)
    end

    subject(:entry) { updater.send(:build_whats_new_entry, {}, feature, release_date, '19.2') }

    it 'maps the feature frontmatter onto a What\'s New entry' do
      expect(entry).to eq(
        'name' => 'Test Feature',
        'description' => "GitLab 19.2 introduces auto-remediation.\n",
        'stage' => 'software_supply_chain_security',
        'self-managed' => true,
        'gitlab-com' => true,
        'available_in' => ['Ultimate'],
        'documentation_link' =>
          'https://docs.gitlab.com/test/test/',
        'published_at' => Date.new(2026, 7, 16),
        'release' => '19.2'
      )
    end

    it 'does not add an image_url key' do
      expect(entry).not_to have_key('image_url')
    end

    it 'dumps available_in as an inline array' do
      expect(YAML.dump([entry])).to include('available_in: [Ultimate]')
    end

    context 'when the feature is not available on GitLab.com' do
      let(:feature_doc) do
        <<~MD
          ---
          title: Self-managed only feature
          tier: [ Premium, Ultimate ]
          offering: [ self_managed ]
          stage: create
          documentation_link: "../../test/test.md"
          level: primary
          ---

          Body.
        MD
      end

      it 'sets gitlab-com to false and self-managed to true' do
        expect(entry).to include('gitlab-com' => false, 'self-managed' => true)
      end

      it 'keeps every tier in available_in' do
        expect(entry).to include('available_in' => %w[Premium Ultimate])
      end
    end

    context 'when the body links to another docs page' do
      let(:feature_doc) do
        <<~MD
          ---
          title: Linking feature
          tier: [ Ultimate ]
          offering: [ gitlab_com ]
          stage: create
          documentation_link: "../../test/test.md"
          level: primary
          ---

          Read the [SAST docs](../../../user/application_security/sast/gitlab_advanced_sast.md).
        MD
      end

      it 'rewrites the link in the description to an absolute URL' do
        expect(entry).to include(
          'description' =>
            'Read the [SAST docs](https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast/).' \
            "\n"
        )
      end
    end
  end

  describe '#dump_entries' do
    def dump(body)
      updater.send(:dump_entries, [{ 'description' => updater.send(:block_scalar_body, body) }])
    end

    it 'dumps a multi-paragraph description as a literal block' do
      expect(dump("First paragraph.\n\nSecond paragraph.\n")).to eq(<<~YAML)
        - description: |
            First paragraph.

            Second paragraph.
      YAML
    end

    it 'dumps a single-paragraph description as a literal block rather than folding it' do
      body = "One paragraph long enough that Psych would otherwise fold it across several lines.\n"

      expect(dump(body)).to eq(<<~YAML)
        - description: |
            One paragraph long enough that Psych would otherwise fold it across several lines.
      YAML
    end

    it 'strips the trailing whitespace that would force Psych into a quoted scalar' do
      expect(dump("Trailing space here. \nNext line.\n")).to eq(<<~YAML)
        - description: |
            Trailing space here.
            Next line.
      YAML
    end
  end

  describe '#sort_features' do
    let(:tmpdir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(tmpdir)
    end

    def build_feature(filename, weight: nil)
      frontmatter = {
        'title' => filename,
        'tier' => ['Ultimate'],
        'offering' => %w[gitlab_com self_managed],
        'stage' => 'create',
        'documentation_link' => '../../test/test.md',
        'level' => 'primary'
      }
      frontmatter['weight'] = weight unless weight.nil?

      path = File.join(tmpdir, filename)
      File.write(path, "#{frontmatter.to_yaml}---\n\n#{filename} body.\n")

      metadata, body = updater.send(:extract_frontmatter, path)
      UpdateWhatsNewContent::Feature.new(path, metadata, body)
    end

    def sorted_filenames(features)
      updater.send(:sort_features, features).map { |feature| File.basename(feature.path) }
    end

    it 'sorts weighted features in ascending weight order' do
      features = [
        build_feature('third.md', weight: 30),
        build_feature('first.md', weight: 10),
        build_feature('second.md', weight: 20)
      ]

      expect(sorted_filenames(features)).to eq(%w[first.md second.md third.md])
    end

    it 'places features without a weight after weighted features' do
      features = [
        build_feature('no-weight.md'),
        build_feature('second.md', weight: 90),
        build_feature('first.md', weight: 10)
      ]

      expect(sorted_filenames(features)).to eq(%w[first.md second.md no-weight.md])
    end

    it 'breaks ties between equal weights by filename' do
      features = [
        build_feature('c.md', weight: 50),
        build_feature('a.md', weight: 50),
        build_feature('b.md', weight: 50)
      ]

      expect(sorted_filenames(features)).to eq(%w[a.md b.md c.md])
    end
  end

  describe '#current_release' do
    let(:releases) do
      [
        { 'version' => '19.1', 'date' => '2026-06-18' },
        { 'version' => '19.2', 'date' => '2026-07-16' },
        { 'version' => '19.3', 'date' => '2026-08-20' }
      ]
    end

    subject(:upcoming) { updater.send(:current_release, releases) }

    context 'on the Monday of release week' do
      let(:today) { Date.new(2026, 7, 13) }

      it 'returns nil rather than picking the release that has not shipped yet' do
        expect(upcoming).to be_nil
      end
    end

    context 'on release day itself' do
      let(:today) { Date.new(2026, 7, 16) }

      it 'selects that release' do
        expect(upcoming).to include('version' => '19.2')
      end
    end

    context 'when just past the release week' do
      let(:today) { Date.new(2026, 7, 17) }

      it 'returns nil rather than picking the release that already shipped' do
        expect(upcoming).to be_nil
      end
    end

    context 'when there are no releases' do
      let(:releases) { [] }

      it 'returns nil' do
        expect(upcoming).to be_nil
      end
    end

    context 'when the run is forced' do
      let(:force) { true }

      context 'on release day itself' do
        let(:today) { Date.new(2026, 7, 16) }

        it 'selects that release' do
          expect(upcoming).to include('version' => '19.2')
        end
      end

      context 'when the nearest release is still upcoming' do
        let(:today) { Date.new(2026, 8, 5) }

        it 'selects the upcoming release rather than the one that already shipped' do
          expect(upcoming).to include('version' => '19.3')
        end
      end

      context 'when the nearest release has already shipped' do
        let(:today) { Date.new(2026, 7, 17) }

        it 'selects the release that shipped' do
          expect(upcoming).to include('version' => '19.2')
        end
      end

      context 'when today is equidistant between two releases' do
        # The default fixture spans an odd number of days, so no date can tie between
        # its releases. This one is 30 days wide, putting the tie on 2026-07-31.
        let(:releases) do
          [
            { 'version' => '19.2', 'date' => '2026-07-16' },
            { 'version' => '19.3', 'date' => '2026-08-15' }
          ]
        end

        let(:today) { Date.new(2026, 7, 31) }

        it 'prefers the upcoming release' do
          expect(upcoming).to include('version' => '19.3')
        end
      end

      context 'when there are no releases' do
        let(:releases) { [] }

        it 'returns nil' do
          expect(upcoming).to be_nil
        end
      end

      context 'when no release carries a date' do
        let(:releases) { [{ 'version' => '19.2' }] }

        it 'returns nil' do
          expect(upcoming).to be_nil
        end
      end
    end
  end

  describe '#absolute_doc_links' do
    def absolute_link(body)
      updater.send(:absolute_doc_links, body)
    end

    it 'rewrites a relative page link to an absolute docs.gitlab.com URL' do
      expect(absolute_link('See [SAST](../../../user/application_security/sast/gitlab_advanced_sast.md).'))
        .to eq('See [SAST](https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast/).')
    end

    it 'rewrites a link to a section index page to the section URL' do
      expect(absolute_link('See [flows](../../../user/duo_agent_platform/flows/_index.md).'))
        .to eq('See [flows](https://docs.gitlab.com/user/duo_agent_platform/flows/).')
    end

    it 'keeps the anchor when rewriting a link' do
      expect(absolute_link('See [audit events](../../../user/compliance/audit_event_types.md#secret-detection).'))
        .to eq('See [audit events](https://docs.gitlab.com/user/compliance/audit_event_types/#secret-detection).')
    end

    it 'rewrites every relative link in the body' do
      body = "[one](../../../ci/pipelines/_index.md) and [two](../../../user/clusters/agent/_index.md)\n"

      expect(absolute_link(body))
        .to eq("[one](https://docs.gitlab.com/ci/pipelines/) and [two](https://docs.gitlab.com/user/clusters/agent/)\n")
    end

    it 'leaves absolute links and in-page anchors untouched' do
      body = 'See [the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/1) and [below](#details).'

      expect(absolute_link(body)).to eq(body)
    end

    it 'returns a body without links unchanged' do
      expect(absolute_link("GitLab 19.2 introduces auto-remediation.\n"))
        .to eq("GitLab 19.2 introduces auto-remediation.\n")
    end
  end

  describe '#docs_url' do
    def docs_url(link)
      updater.send(:docs_url, link)
    end

    it 'rewrites a relative page link to an absolute docs.gitlab.com URL' do
      expect(docs_url('../../../user/application_security/sast/gitlab_advanced_sast.md'))
        .to eq('https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast/')
    end

    it 'keeps the anchor when rewriting a link' do
      expect(docs_url('../../../user/compliance/audit_event_types.md#secret-detection'))
        .to eq('https://docs.gitlab.com/user/compliance/audit_event_types/#secret-detection')
    end

    it 'leaves absolute links untouched' do
      expect(docs_url('https://docs.gitlab.com/runner')).to eq('https://docs.gitlab.com/runner')
    end
  end
end
