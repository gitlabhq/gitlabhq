require 'spec_helper'

describe ApplicationSetting, models: true do
  let(:setting) { ApplicationSetting.create_from_defaults }

  it { expect(setting).to be_valid }
  it { expect(setting.uuid).to be_present }

  describe 'validations' do
    let(:http)  { 'http://example.com' }
    let(:https) { 'https://example.com' }
    let(:ftp)   { 'ftp://example.com' }

    it { is_expected.to allow_value(nil).for(:home_page_url) }
    it { is_expected.to allow_value(http).for(:home_page_url) }
    it { is_expected.to allow_value(https).for(:home_page_url) }
    it { is_expected.not_to allow_value(ftp).for(:home_page_url) }

    it { is_expected.to allow_value(nil).for(:after_sign_out_path) }
    it { is_expected.to allow_value(http).for(:after_sign_out_path) }
    it { is_expected.to allow_value(https).for(:after_sign_out_path) }
    it { is_expected.not_to allow_value(ftp).for(:after_sign_out_path) }

    describe 'disabled_oauth_sign_in_sources validations' do
      before do
        allow(Devise).to receive(:omniauth_providers).and_return([:github])
      end

      it { is_expected.to allow_value(['github']).for(:disabled_oauth_sign_in_sources) }
      it { is_expected.not_to allow_value(['test']).for(:disabled_oauth_sign_in_sources) }
    end

    describe 'default_artifacts_expire_in' do
      it 'sets an error if it cannot parse' do
        setting.update(default_artifacts_expire_in: 'a')

        expect_invalid
      end

      it 'sets an error if it is blank' do
        setting.update(default_artifacts_expire_in: ' ')

        expect_invalid
      end

      it 'sets the value if it is valid' do
        setting.update(default_artifacts_expire_in: '30 days')

        expect(setting).to be_valid
        expect(setting.default_artifacts_expire_in).to eq('30 days')
      end

      it 'sets the value if it is 0' do
        setting.update(default_artifacts_expire_in: '0')

        expect(setting).to be_valid
        expect(setting.default_artifacts_expire_in).to eq('0')
      end

      def expect_invalid
        expect(setting).to be_invalid
        expect(setting.errors.messages)
          .to have_key(:default_artifacts_expire_in)
      end
    end

    it { is_expected.to validate_presence_of(:max_attachment_size) }

    it do
      is_expected.to validate_numericality_of(:max_attachment_size)
        .only_integer
        .is_greater_than(0)
    end

    it_behaves_like 'an object with email-formated attributes', :admin_notification_email do
      subject { setting }
    end

    # Upgraded databases will have this sort of content
    context 'repository_storages is a String, not an Array' do
      before do
        setting.__send__(:raw_write_attribute, :repository_storages, 'default')
      end

      it { expect(setting.repository_storages_before_type_cast).to eq('default') }
      it { expect(setting.repository_storages).to eq(['default']) }
    end

    context 'repository storages' do
      before do
        storages = {
          'custom1' => 'tmp/tests/custom_repositories_1',
          'custom2' => 'tmp/tests/custom_repositories_2',
          'custom3' => 'tmp/tests/custom_repositories_3'

        }
        allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
      end

      describe 'inclusion' do
        it { is_expected.to allow_value('custom1').for(:repository_storages) }
        it { is_expected.to allow_value(%w(custom2 custom3)).for(:repository_storages) }
        it { is_expected.not_to allow_value('alternative').for(:repository_storages) }
        it { is_expected.not_to allow_value(%w(alternative custom1)).for(:repository_storages) }
      end

      describe 'presence' do
        it { is_expected.not_to allow_value([]).for(:repository_storages) }
        it { is_expected.not_to allow_value("").for(:repository_storages) }
        it { is_expected.not_to allow_value(nil).for(:repository_storages) }
      end

      describe '.pick_repository_storage' do
        it 'uses Array#sample to pick a random storage' do
          array = double('array', sample: 'random')
          expect(setting).to receive(:repository_storages).and_return(array)

          expect(setting.pick_repository_storage).to eq('random')
        end

        describe '#repository_storage' do
          it 'returns the first storage' do
            setting.repository_storages = %w(good bad)

            expect(setting.repository_storage).to eq('good')
          end
        end

        describe '#repository_storage=' do
          it 'overwrites repository_storages' do
            setting.repository_storage = 'overwritten'

            expect(setting.repository_storages).to eq(['overwritten'])
          end
        end
      end
    end

    context 'housekeeping settings' do
      it { is_expected.not_to allow_value(0).for(:housekeeping_incremental_repack_period) }

      it 'wants the full repack period to be longer than the incremental repack period' do
        subject.housekeeping_incremental_repack_period = 2
        subject.housekeeping_full_repack_period = 1

        expect(subject).not_to be_valid
      end

      it 'wants the gc period to be longer than the full repack period' do
        subject.housekeeping_full_repack_period = 2
        subject.housekeeping_gc_period = 1

        expect(subject).not_to be_valid
      end
    end
  end

  describe '.current' do
    context 'redis unavailable' do
      it 'returns an ApplicationSetting' do
        allow(Rails.cache).to receive(:fetch).and_call_original
        allow(ApplicationSetting).to receive(:last).and_return(:last)
        expect(Rails.cache).to receive(:fetch).with(ApplicationSetting::CACHE_KEY).and_raise(ArgumentError)

        expect(ApplicationSetting.current).to eq(:last)
      end
    end
  end

  context 'restricted signup domains' do
    it 'sets single domain' do
      setting.domain_whitelist_raw = 'example.com'
      expect(setting.domain_whitelist).to eq(['example.com'])
    end

    it 'sets multiple domains with spaces' do
      setting.domain_whitelist_raw = 'example.com *.example.com'
      expect(setting.domain_whitelist).to eq(['example.com', '*.example.com'])
    end

    it 'sets multiple domains with newlines and a space' do
      setting.domain_whitelist_raw = "example.com\n *.example.com"
      expect(setting.domain_whitelist).to eq(['example.com', '*.example.com'])
    end

    it 'sets multiple domains with commas' do
      setting.domain_whitelist_raw = "example.com, *.example.com"
      expect(setting.domain_whitelist).to eq(['example.com', '*.example.com'])
    end
  end

  context 'blacklisted signup domains' do
    it 'sets single domain' do
      setting.domain_blacklist_raw = 'example.com'
      expect(setting.domain_blacklist).to contain_exactly('example.com')
    end

    it 'sets multiple domains with spaces' do
      setting.domain_blacklist_raw = 'example.com *.example.com'
      expect(setting.domain_blacklist).to contain_exactly('example.com', '*.example.com')
    end

    it 'sets multiple domains with newlines and a space' do
      setting.domain_blacklist_raw = "example.com\n *.example.com"
      expect(setting.domain_blacklist).to contain_exactly('example.com', '*.example.com')
    end

    it 'sets multiple domains with commas' do
      setting.domain_blacklist_raw = "example.com, *.example.com"
      expect(setting.domain_blacklist).to contain_exactly('example.com', '*.example.com')
    end

    it 'sets multiple domains with semicolon' do
      setting.domain_blacklist_raw = "example.com; *.example.com"
      expect(setting.domain_blacklist).to contain_exactly('example.com', '*.example.com')
    end

    it 'sets multiple domains with mixture of everything' do
      setting.domain_blacklist_raw = "example.com; *.example.com\n test.com\sblock.com   yes.com"
      expect(setting.domain_blacklist).to contain_exactly('example.com', '*.example.com', 'test.com', 'block.com', 'yes.com')
    end

    it 'sets multiple domain with file' do
      setting.domain_blacklist_file = File.open(Rails.root.join('spec/fixtures/', 'domain_blacklist.txt'))
      expect(setting.domain_blacklist).to contain_exactly('example.com', 'test.com', 'foo.bar')
    end
  end

  describe 'performance bar settings' do
    describe 'performance_bar_allowed_group_id=' do
      context 'with a blank path' do
        before do
          setting.performance_bar_allowed_group_id = create(:group).full_path
        end

        it 'persists nil for a "" path and clears allowed user IDs cache' do
          expect(Gitlab::PerformanceBar).to receive(:expire_allowed_user_ids_cache)

          setting.performance_bar_allowed_group_id = ''

          expect(setting.performance_bar_allowed_group_id).to be_nil
        end
      end

      context 'with an invalid path' do
        it 'does not persist an invalid group path' do
          setting.performance_bar_allowed_group_id = 'foo'

          expect(setting.performance_bar_allowed_group_id).to be_nil
        end
      end

      context 'with a path to an existing group' do
        let(:group) { create(:group) }

        it 'persists a valid group path and clears allowed user IDs cache' do
          expect(Gitlab::PerformanceBar).to receive(:expire_allowed_user_ids_cache)

          setting.performance_bar_allowed_group_id = group.full_path

          expect(setting.performance_bar_allowed_group_id).to eq(group.id)
        end

        context 'when the given path is the same' do
          context 'with a blank path' do
            before do
              setting.performance_bar_allowed_group_id = nil
            end

            it 'clears the cached allowed user IDs' do
              expect(Gitlab::PerformanceBar).not_to receive(:expire_allowed_user_ids_cache)

              setting.performance_bar_allowed_group_id = ''
            end
          end

          context 'with a valid path' do
            before do
              setting.performance_bar_allowed_group_id = group.full_path
            end

            it 'clears the cached allowed user IDs' do
              expect(Gitlab::PerformanceBar).not_to receive(:expire_allowed_user_ids_cache)

              setting.performance_bar_allowed_group_id = group.full_path
            end
          end
        end
      end
    end

    describe 'performance_bar_allowed_group' do
      context 'with no performance_bar_allowed_group_id saved' do
        it 'returns nil' do
          expect(setting.performance_bar_allowed_group).to be_nil
        end
      end

      context 'with a performance_bar_allowed_group_id saved' do
        let(:group) { create(:group) }

        before do
          setting.performance_bar_allowed_group_id = group.full_path
        end

        it 'returns the group' do
          expect(setting.performance_bar_allowed_group).to eq(group)
        end
      end
    end

    describe 'performance_bar_enabled' do
      context 'with the Performance Bar is enabled' do
        let(:group) { create(:group) }

        before do
          setting.performance_bar_allowed_group_id = group.full_path
        end

        it 'returns true' do
          expect(setting.performance_bar_enabled).to be_truthy
        end
      end
    end

    describe 'performance_bar_enabled=' do
      context 'when the performance bar is enabled' do
        let(:group) { create(:group) }

        before do
          setting.performance_bar_allowed_group_id = group.full_path
        end

        context 'when passing true' do
          it 'does not clear allowed user IDs cache' do
            expect(Gitlab::PerformanceBar).not_to receive(:expire_allowed_user_ids_cache)

            setting.performance_bar_enabled = true

            expect(setting.performance_bar_allowed_group_id).to eq(group.id)
            expect(setting.performance_bar_enabled).to be_truthy
          end
        end

        context 'when passing false' do
          it 'disables the performance bar and clears allowed user IDs cache' do
            expect(Gitlab::PerformanceBar).to receive(:expire_allowed_user_ids_cache)

            setting.performance_bar_enabled = false

            expect(setting.performance_bar_allowed_group_id).to be_nil
            expect(setting.performance_bar_enabled).to be_falsey
          end
        end
      end

      context 'when the performance bar is disabled' do
        context 'when passing true' do
          it 'does nothing and does not clear allowed user IDs cache' do
            expect(Gitlab::PerformanceBar).not_to receive(:expire_allowed_user_ids_cache)

            setting.performance_bar_enabled = true

            expect(setting.performance_bar_allowed_group_id).to be_nil
            expect(setting.performance_bar_enabled).to be_falsey
          end
        end

        context 'when passing false' do
          it 'does nothing and does not clear allowed user IDs cache' do
            expect(Gitlab::PerformanceBar).not_to receive(:expire_allowed_user_ids_cache)

            setting.performance_bar_enabled = false

            expect(setting.performance_bar_allowed_group_id).to be_nil
            expect(setting.performance_bar_enabled).to be_falsey
          end
        end
      end
    end
  end

  describe 'usage ping settings' do
    context 'when the usage ping is disabled in gitlab.yml' do
      before do
        allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(false)
      end

      it 'does not allow the usage ping to be configured' do
        expect(setting.usage_ping_can_be_configured?).to be_falsey
      end

      context 'when the usage ping is disabled in the DB' do
        before do
          setting.usage_ping_enabled = false
        end

        it 'returns false for usage_ping_enabled' do
          expect(setting.usage_ping_enabled).to be_falsey
        end
      end

      context 'when the usage ping is enabled in the DB' do
        before do
          setting.usage_ping_enabled = true
        end

        it 'returns false for usage_ping_enabled' do
          expect(setting.usage_ping_enabled).to be_falsey
        end
      end
    end

    context 'when the usage ping is enabled in gitlab.yml' do
      before do
        allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(true)
      end

      it 'allows the usage ping to be configured' do
        expect(setting.usage_ping_can_be_configured?).to be_truthy
      end

      context 'when the usage ping is disabled in the DB' do
        before do
          setting.usage_ping_enabled = false
        end

        it 'returns false for usage_ping_enabled' do
          expect(setting.usage_ping_enabled).to be_falsey
        end
      end

      context 'when the usage ping is enabled in the DB' do
        before do
          setting.usage_ping_enabled = true
        end

        it 'returns true for usage_ping_enabled' do
          expect(setting.usage_ping_enabled).to be_truthy
        end
      end
    end
  end

  describe '#repository_size_limit column' do
    it 'support values up to 8 exabytes' do
      setting.update_column(:repository_size_limit, 8.exabytes - 1)

      setting.reload

      expect(setting.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe 'elasticsearch licensing' do
    before do
      setting.elasticsearch_search = true
      setting.elasticsearch_indexing = true
    end

    def expect_is_es_licensed
      expect(License).to receive(:feature_available?).with(:elastic_search).at_least(:once)
    end

    it 'disables elasticsearch when unlicensed' do
      expect_is_es_licensed.and_return(false)

      expect(setting.elasticsearch_indexing?).to be_falsy
      expect(setting.elasticsearch_indexing).to be_falsy
      expect(setting.elasticsearch_search?).to be_falsy
      expect(setting.elasticsearch_search).to be_falsy
    end

    it 'enables elasticsearch when licensed' do
      expect_is_es_licensed.and_return(true)

      expect(setting.elasticsearch_indexing?).to be_truthy
      expect(setting.elasticsearch_indexing).to be_truthy
      expect(setting.elasticsearch_search?).to be_truthy
      expect(setting.elasticsearch_search).to be_truthy
    end
  end

  describe '#elasticsearch_url' do
    it 'presents a single URL as a one-element array' do
      setting.elasticsearch_url = 'http://example.com'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com])
    end

    it 'presents multiple URLs as a many-element array' do
      setting.elasticsearch_url = 'http://example.com,https://invalid.invalid:9200'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://invalid.invalid:9200])
    end

    it 'strips whitespace from around URLs' do
      setting.elasticsearch_url = ' http://example.com, https://invalid.invalid:9200 '

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://invalid.invalid:9200])
    end

    it 'strips trailing slashes from URLs' do
      setting.elasticsearch_url = 'http://example.com/, https://example.com:9200/, https://example.com:9200/prefix//'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://example.com:9200 https://example.com:9200/prefix])
    end
  end

  describe '#elasticsearch_config' do
    it 'places all elasticsearch configuration values into a hash' do
      setting.update!(
        elasticsearch_url: 'http://example.com:9200',
        elasticsearch_aws: false,
        elasticsearch_aws_region:     'test-region',
        elasticsearch_aws_access_key: 'test-access-key',
        elasticsearch_aws_secret_access_key: 'test-secret-access-key'
      )

      expect(setting.elasticsearch_config).to eq(
        url: ['http://example.com:9200'],
        aws: false,
        aws_region:     'test-region',
        aws_access_key: 'test-access-key',
        aws_secret_access_key: 'test-secret-access-key'
      )
    end
  end
end
