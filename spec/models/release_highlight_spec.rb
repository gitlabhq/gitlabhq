# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleaseHighlight, :clean_gitlab_redis_cache, feature_category: :release_orchestration do
  let(:fixture_dir_glob) { Dir.glob(File.join(Rails.root, 'spec', 'fixtures', 'whats_new', '*.yml')).grep(/\d*_(\d*_\d*)\.yml$/) }

  before do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with(described_class.whats_new_path).and_return(fixture_dir_glob)
    Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:all_tiers])
  end

  after do
    described_class.instance_variable_set(:@file_paths, nil)
  end

  describe '.paginated_query' do
    context 'with page param' do
      subject { described_class.paginated_query(page: page) }

      context 'when there is another page of results' do
        let(:page) { 3 }

        it 'responds with paginated query results' do
          expect(subject[:items].first['name']).to eq('bright')
          expect(subject[:next_page]).to eq(4)
        end
      end

      context 'when there is NOT another page of results' do
        let(:page) { 4 }

        it 'responds with paginated query results and no next_page' do
          expect(subject[:items].first['name']).to eq("It's gonna be a bright")
          expect(subject[:next_page]).to eq(nil)
        end
      end

      context 'when that specific page does not exist' do
        let(:page) { 84 }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '.paginated' do
    context 'with no page param' do
      subject { described_class.paginated }

      it 'uses multiple levels of cache' do
        expect(Rails.cache).to receive(:fetch).with("release_highlight:all_tiers:items:page-1:#{Gitlab.revision}", { expires_in: described_class::CACHE_DURATION }).and_call_original
        expect(Rails.cache).to receive(:fetch).with("release_highlight:all_tiers:file_paths:#{Gitlab.revision}", { expires_in: described_class::CACHE_DURATION }).and_call_original

        subject
      end

      it 'returns platform specific items' do
        expect(subject[:items].count).to eq(1)
        expect(subject[:items].first['name']).to eq("bright and sunshinin' day")
        expect(subject[:next_page]).to eq(2)
      end

      it 'parses the description as markdown and returns html, and links are target="_blank"' do
        stub_commonmark_sourcepos_disabled

        expect(subject[:items].first['description']).to eq('<p dir="auto">bright and sunshinin\' <a href="https://en.wikipedia.org/wiki/Day" rel="nofollow noreferrer noopener" target="_blank">day</a></p>')
      end

      it 'logs an error if theres an error parsing markdown for an item, and skips it' do
        whats_new_items_count = 6

        allow(Banzai).to receive(:render).and_raise

        expect(Gitlab::ErrorTracking).to receive(:track_exception).exactly(whats_new_items_count).times
        expect(subject[:items]).to be_empty
      end

      context 'when Gitlab.com', :saas do
        it 'responds with a different set of data' do
          expect(subject[:items].count).to eq(1)
          expect(subject[:items].first['name']).to eq("I think I can make it now the pain is gone")
        end
      end

      context 'YAML parsing throws an exception' do
        it 'fails gracefully and logs an error' do
          whats_new_files_count = 4

          allow(YAML).to receive(:safe_load).and_raise(Psych::Exception)

          expect(Gitlab::ErrorTracking).to receive(:track_exception).exactly(whats_new_files_count).times
          expect(subject[:items]).to be_empty
        end
      end
    end
  end

  describe '.most_recent_item_count' do
    subject { described_class.most_recent_item_count }

    it 'uses process memory cache' do
      expect(Gitlab::ProcessMemoryCache.cache_backend).to receive(:fetch).with("release_highlight:all_tiers:recent_item_count:#{Gitlab.revision}", expires_in: described_class::CACHE_DURATION)

      subject
    end

    context 'when recent release items exist' do
      it 'returns the count from the most recent file' do
        allow(described_class).to receive(:paginated).and_return(double(:paginated, items: [double(:item)]))

        expect(subject).to eq(1)
      end
    end

    context 'when recent release items do NOT exist' do
      it 'returns nil' do
        allow(described_class).to receive(:paginated).and_return(nil)

        expect(subject).to be_nil
      end
    end
  end

  describe '.most_recent_version_digest' do
    subject { described_class.most_recent_version_digest }

    it 'uses process memory cache' do
      expect(Gitlab::ProcessMemoryCache.cache_backend).to receive(:fetch).with("release_highlight:all_tiers:most_recent_version_digest:#{Gitlab.revision}", expires_in: described_class::CACHE_DURATION)

      subject
    end

    context 'when recent release items exist' do
      it 'returns a digest from the release of the first item of the most recent file' do
        # this value is coming from fixture data
        expect(subject).to eq(Digest::SHA256.hexdigest('01.05'))
      end
    end

    context 'when recent release items do NOT exist' do
      it 'returns nil' do
        allow(described_class).to receive(:paginated).and_return(nil)

        expect(subject).to be_nil
      end
    end
  end

  describe '.load_items' do
    context 'whats new for all tiers' do
      before do
        Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:all_tiers])
      end

      it 'returns all items' do
        items = described_class.load_items(page: 2)

        expect(items.count).to eq(3)
      end
    end

    context 'whats new for current tier only' do
      before do
        Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:current_tier])
      end

      it 'returns items with package=Free' do
        items = described_class.load_items(page: 2)

        expect(items.count).to eq(1)
        expect(items.first['name']).to eq("View epics on a board")
      end
    end

    context 'YAML parsing throws an exception' do
      it 'fails gracefully and logs an error' do
        allow(YAML).to receive(:safe_load).and_raise(Psych::Exception)

        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        items = described_class.load_items(page: 2)

        expect(items).to be_empty
      end
    end
  end

  describe 'QueryResult' do
    subject { ReleaseHighlight::QueryResult.new(items: items, next_page: 2) }

    let(:items) { [:item] }

    it 'responds to map' do
      expect(subject.map(&:to_s)).to eq(items.map(&:to_s))
    end
  end

  describe '.current_package' do
    subject { described_class.current_package }

    it 'returns Free' do
      expect(subject).to eq('Free')
    end
  end

  describe '.file_paths' do
    it 'joins relative file paths with the root path to avoid caching the root url' do
      allow(described_class).to receive(:relative_file_paths).and_return([+'/a.yml'])

      expect(described_class.file_paths.first).to eq("#{Rails.root}/a.yml")
    end
  end
end
