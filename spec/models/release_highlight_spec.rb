# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleaseHighlight, :clean_gitlab_redis_cache do
  let(:fixture_dir_glob) { Dir.glob(File.join('spec', 'fixtures', 'whats_new', '*.yml')).grep(/\d*\_(\d*\_\d*)\.yml$/) }

  before do
    allow(Dir).to receive(:glob).with(Rails.root.join('data', 'whats_new', '*.yml')).and_return(fixture_dir_glob)
    Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:all_tiers])
  end

  after do
    ReleaseHighlight.instance_variable_set(:@file_paths, nil)
  end

  describe '.paginated' do
    let(:dot_com) { false }

    before do
      allow(Gitlab).to receive(:com?).and_return(dot_com)
    end

    context 'with page param' do
      subject { ReleaseHighlight.paginated(page: page) }

      context 'when there is another page of results' do
        let(:page) { 3 }

        it 'responds with paginated results' do
          expect(subject[:items].first['title']).to eq('bright')
          expect(subject[:next_page]).to eq(4)
        end
      end

      context 'when there is NOT another page of results' do
        let(:page) { 4 }

        it 'responds with paginated results and no next_page' do
          expect(subject[:items].first['title']).to eq("It's gonna be a bright")
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

    context 'with no page param' do
      subject { ReleaseHighlight.paginated }

      it 'uses multiple levels of cache' do
        expect(Rails.cache).to receive(:fetch).with("release_highlight:all_tiers:items:page-1:#{Gitlab.revision}", { expires_in: described_class::CACHE_DURATION }).and_call_original
        expect(Rails.cache).to receive(:fetch).with("release_highlight:all_tiers:file_paths:#{Gitlab.revision}", { expires_in: described_class::CACHE_DURATION }).and_call_original

        subject
      end

      it 'returns platform specific items' do
        expect(subject[:items].count).to eq(1)
        expect(subject[:items].first['title']).to eq("bright and sunshinin' day")
        expect(subject[:next_page]).to eq(2)
      end

      it 'parses the body as markdown and returns html, and links are target="_blank"' do
        expect(subject[:items].first['body']).to match('<p data-sourcepos="1:1-1:62" dir="auto">bright and sunshinin\' <a href="https://en.wikipedia.org/wiki/Day" rel="nofollow noreferrer noopener" target="_blank">day</a></p>')
      end

      it 'logs an error if theres an error parsing markdown for an item, and skips it' do
        allow(Banzai).to receive(:render).and_raise

        expect(Gitlab::ErrorTracking).to receive(:track_exception)
        expect(subject[:items]).to be_empty
      end

      context 'when Gitlab.com' do
        let(:dot_com) { true }

        it 'responds with a different set of data' do
          expect(subject[:items].count).to eq(1)
          expect(subject[:items].first['title']).to eq("I think I can make it now the pain is gone")
        end
      end

      context 'YAML parsing throws an exception' do
        it 'fails gracefully and logs an error' do
          allow(YAML).to receive(:safe_load).and_raise(Psych::Exception)

          expect(Gitlab::ErrorTracking).to receive(:track_exception)
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '.most_recent_item_count' do
    subject { ReleaseHighlight.most_recent_item_count }

    it 'uses process memory cache' do
      expect(Gitlab::ProcessMemoryCache.cache_backend).to receive(:fetch).with("release_highlight:all_tiers:recent_item_count:#{Gitlab.revision}", expires_in: described_class::CACHE_DURATION)

      subject
    end

    context 'when recent release items exist' do
      it 'returns the count from the most recent file' do
        allow(ReleaseHighlight).to receive(:paginated).and_return(double(:paginated, items: [double(:item)]))

        expect(subject).to eq(1)
      end
    end

    context 'when recent release items do NOT exist' do
      it 'returns nil' do
        allow(ReleaseHighlight).to receive(:paginated).and_return(nil)

        expect(subject).to be_nil
      end
    end
  end

  describe '.most_recent_version_digest' do
    subject { ReleaseHighlight.most_recent_version_digest }

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
        allow(ReleaseHighlight).to receive(:paginated).and_return(nil)

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
        expect(items.first['title']).to eq("View epics on a board")
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
end
