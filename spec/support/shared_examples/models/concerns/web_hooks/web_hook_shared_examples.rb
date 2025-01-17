# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a webhook' do |factory:, auto_disabling: true|
  include AfterNextHelpers

  let(:hook) { build(factory) }

  around do |example|
    if example.metadata[:skip_freeze_time]
      example.run
    else
      freeze_time { example.run }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_length_of(:custom_webhook_template).is_at_most(4096) }

    describe 'url_variables' do
      it { is_expected.to allow_value({}).for(:url_variables) }
      it { is_expected.to allow_value({ 'foo' => 'bar' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'FOO' => 'bar' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'MY_TOKEN' => 'bar' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'foo2' => 'bar' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'x' => 'y' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'x' => ('a' * 2048) }).for(:url_variables) }
      it { is_expected.to allow_value({ 'foo' => 'bar', 'bar' => 'baz' }).for(:url_variables) }
      it { is_expected.to allow_value((1..20).to_h { |i| ["k#{i}", 'value'] }).for(:url_variables) }
      it { is_expected.to allow_value({ 'MY-TOKEN' => 'bar' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'my_secr3t-token' => 'bar' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'x-y-z' => 'bar' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'x_y_z' => 'bar' }).for(:url_variables) }
      it { is_expected.to allow_value({ 'f.o.o' => 'bar' }).for(:url_variables) }

      it { is_expected.not_to allow_value([]).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'foo' => 1 }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'bar' => :baz }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'bar' => nil }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'foo' => '' }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'foo' => ('a' * 2049) }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'has spaces' => 'foo' }).for(:url_variables) }
      it { is_expected.not_to allow_value({ '' => 'foo' }).for(:url_variables) }
      it { is_expected.not_to allow_value({ '1foo' => 'foo' }).for(:url_variables) }
      it { is_expected.not_to allow_value((1..21).to_h { |i| ["k#{i}", 'value'] }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'MY--TOKEN' => 'foo' }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'MY__SECRET' => 'foo' }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'x-_y' => 'foo' }).for(:url_variables) }
      it { is_expected.not_to allow_value({ 'x..y' => 'foo' }).for(:url_variables) }
    end

    describe 'custom_headers' do
      it { is_expected.to allow_value({}).for(:custom_headers) }
      it { is_expected.to allow_value({ 'foo' => 'bar' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'FOO' => 'bar' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'MY_TOKEN' => 'bar' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'foo2' => 'bar' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'x' => 'y' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'x' => ('a' * 2048) }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'foo' => 'bar', 'bar' => 'baz' }).for(:custom_headers) }
      it { is_expected.to allow_value((1..20).to_h { |i| ["k#{i}", 'value'] }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'MY-TOKEN' => 'bar' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'my_secr3t-token' => 'bar' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'x-y-z' => 'bar' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'x_y_z' => 'bar' }).for(:custom_headers) }
      it { is_expected.to allow_value({ 'f.o.o' => 'bar' }).for(:custom_headers) }

      it { is_expected.not_to allow_value([]).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'foo' => 1 }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'bar' => :baz }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'bar' => nil }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'foo' => '' }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'foo' => ('a' * 2049) }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'has spaces' => 'foo' }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ '' => 'foo' }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ '1foo' => 'foo' }).for(:custom_headers) }
      it { is_expected.not_to allow_value((1..21).to_h { |i| ["k#{i}", 'value'] }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'MY--TOKEN' => 'foo' }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'MY__SECRET' => 'foo' }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'x-_y' => 'foo' }).for(:custom_headers) }
      it { is_expected.not_to allow_value({ 'x..y' => 'foo' }).for(:custom_headers) }
    end

    describe 'url' do
      it { is_expected.to allow_value('http://example.com').for(:url) }
      it { is_expected.to allow_value('https://example.com').for(:url) }
      it { is_expected.to allow_value(' https://example.com ').for(:url) }
      it { is_expected.to allow_value('http://test.com/api').for(:url) }
      it { is_expected.to allow_value('http://test.com/api?key=abc').for(:url) }
      it { is_expected.to allow_value('http://test.com/api?key=abc&type=def').for(:url) }

      it { is_expected.not_to allow_value('example.com').for(:url) }
      it { is_expected.not_to allow_value('ftp://example.com').for(:url) }
      it { is_expected.not_to allow_value('herp-and-derp').for(:url) }

      context 'when url is local' do
        let(:url) { 'http://localhost:9000' }

        it { is_expected.not_to allow_value(url).for(:url) }

        it 'is valid if application settings allow local requests from web hooks' do
          settings = ApplicationSetting.new(allow_local_requests_from_web_hooks_and_services: true)
          allow(ApplicationSetting).to receive(:current).and_return(settings)

          is_expected.to allow_value(url).for(:url)
        end
      end

      it 'strips :url before saving it' do
        hook.url = ' https://example.com '
        hook.save!

        expect(hook.url).to eq('https://example.com')
      end

      context 'when there are URL variables' do
        subject { hook }

        before do
          hook.url_variables = { 'one' => 'a', 'two' => 'b', 'url' => 'http://example.com' }
        end

        it { is_expected.to allow_value('http://example.com').for(:url) }
        it { is_expected.to allow_value('http://example.com/{one}/{two}').for(:url) }
        it { is_expected.to allow_value('http://example.com/{one}').for(:url) }
        it { is_expected.to allow_value('http://example.com/{two}').for(:url) }
        it { is_expected.to allow_value('http://user:s3cret@example.com/{two}').for(:url) }
        it { is_expected.to allow_value('http://{one}:{two}@example.com').for(:url) }
        it { is_expected.to allow_value('http://{one}').for(:url) }
        it { is_expected.to allow_value('{url}').for(:url) }

        it { is_expected.not_to allow_value('http://example.com/{one}/{two}/{three}').for(:url) }
        it { is_expected.not_to allow_value('http://example.com/{foo}').for(:url) }
        it { is_expected.not_to allow_value('http:{user}:{pwd}//example.com/{foo}').for(:url) }

        it 'mentions all missing variable names' do
          hook.url = 'http://example.com/{one}/{foo}/{two}/{three}'

          expect(hook).to be_invalid
          expect(hook.errors[:url].to_sentence).to eq "Invalid URL template. Missing keys: [\"foo\", \"three\"]"
        end
      end
    end

    describe 'token' do
      it { is_expected.to allow_value("foobar").for(:token) }

      it { is_expected.not_to allow_values("foo\nbar", "foo\r\nbar").for(:token) }
    end

    describe 'push_events_branch_filter' do
      before do
        subject.branch_filter_strategy = strategy
      end

      context 'with "all branches" strategy' do
        let(:strategy) { 'all_branches' }
        let(:allowed_values) do
          ["good_branch_name", "another/good-branch_name", "good branch name", "good~branchname", "good_branchname(",
            "good_branchname[", ""]
        end

        it { is_expected.to allow_values(*allowed_values).for(:push_events_branch_filter) }
      end

      context 'with "wildcard" strategy' do
        let(:strategy) { 'wildcard' }
        let(:allowed_values) { ["good_branch_name", "another/good-branch_name", "good_branch_name(", ""] }
        let(:disallowed_values) { ["bad branch name", "bad~branchname", "bad_branch_name["] }

        it { is_expected.to allow_values(*allowed_values).for(:push_events_branch_filter) }
        it { is_expected.not_to allow_values(*disallowed_values).for(:push_events_branch_filter) }

        it 'gets rid of whitespace' do
          hook.push_events_branch_filter = ' branch '
          hook.save!

          expect(hook.push_events_branch_filter).to eq('branch')
        end

        it 'stores whitespace only as empty' do
          hook.push_events_branch_filter = ' '
          hook.save!
          expect(hook.push_events_branch_filter).to eq('')
        end
      end

      context 'with "regex" strategy' do
        let(:strategy) { 'regex' }
        let(:allowed_values) do
          ["good_branch_name", "another/good-branch_name", "good branch name", "good~branch~name", ""]
        end

        it { is_expected.to allow_values(*allowed_values).for(:push_events_branch_filter) }
        it { is_expected.not_to allow_values("bad_branch_name(", "bad_branch_name[").for(:push_events_branch_filter) }
      end
    end

    describe 'before_validation :reset_token' do
      subject(:hook) { build_stubbed(factory, :token) }

      it 'resets token if url changed' do
        hook.url = 'https://webhook.example.com/new-hook'

        expect(hook).to be_valid
        expect(hook.token).to be_nil
      end

      it 'does not reset token if new url is set together with the same token' do
        hook.url = 'https://webhook.example.com/new-hook'
        current_token = hook.token
        hook.token = current_token

        expect(hook).to be_valid
        expect(hook.token).to eq(current_token)
        expect(hook.url).to eq('https://webhook.example.com/new-hook')
      end

      it 'does not reset token if new url is set together with a new token' do
        hook.url = 'https://webhook.example.com/new-hook'
        hook.token = 'token'

        expect(hook).to be_valid
        expect(hook.token).to eq('token')
        expect(hook.url).to eq('https://webhook.example.com/new-hook')
      end
    end

    describe 'before_validation :reset_url_variables' do
      subject(:hook) { build_stubbed(factory, :url_variables, url: 'http://example.com/{abc}') }

      it 'resets url variables if url changed' do
        hook.url = 'http://example.com/new-hook'

        expect(hook).to be_valid
        expect(hook.url_variables).to eq({})
      end

      it 'resets url variables if url is changed but url variables stayed the same' do
        hook.url = 'http://test.example.com/{abc}'

        expect(hook).not_to be_valid
        expect(hook.url_variables).to eq({})
      end

      it 'resets url variables if url is changed and url variables are appended' do
        hook.url = 'http://suspicious.example.com/{abc}/{foo}'
        hook.url_variables = hook.url_variables.merge('foo' => 'bar')

        expect(hook).not_to be_valid
        expect(hook.url_variables).to eq({})
      end

      it 'resets url variables if url is changed and url variables are removed' do
        hook.url = 'http://suspicious.example.com/{abc}'
        hook.url_variables = hook.url_variables.except("def")

        expect(hook).not_to be_valid
        expect(hook.url_variables).to eq({})
      end

      it 'resets url variables if url variables are overwritten' do
        hook.url_variables = hook.url_variables.merge('abc' => 'baz')

        expect(hook).not_to be_valid
        expect(hook.url_variables).to eq({})
      end

      it 'does not reset url variables if both url and url variables are changed' do
        hook.url = 'http://example.com/{one}/{two}'
        hook.url_variables = { 'one' => 'foo', 'two' => 'bar' }

        expect(hook).to be_valid
        expect(hook.url_variables).to eq({ 'one' => 'foo', 'two' => 'bar' })
      end

      context 'without url variables' do
        subject(:hook) { build_stubbed(factory, url: 'http://example.com', url_variables: nil) }

        it 'does not reset url variables' do
          hook.url = 'http://example.com/{one}/{two}'
          hook.url_variables = { 'one' => 'foo', 'two' => 'bar' }

          expect(hook).to be_valid
          expect(hook.url_variables).to eq({ 'one' => 'foo', 'two' => 'bar' })
        end
      end
    end

    describe 'before_validation :reset_custom_headers' do
      subject(:hook) { build_stubbed(factory, :url_variables, url: 'http://example.com/{abc}', custom_headers: { test: 'blub' }) }

      it 'resets custom headers if url changed' do
        hook.url = 'http://example.com/new-hook'

        expect(hook).to be_valid
        expect(hook.custom_headers).to eq({})
      end

      it 'resets custom headers if url and url variables changed' do
        hook.url = 'http://example.com/{something}'
        hook.url_variables = { 'something' => 'testing-around' }

        expect(hook).to be_valid
        expect(hook.custom_headers).to eq({})
      end

      it 'does not reset custom headers if url stayed the same' do
        hook.url = 'http://example.com/{abc}'

        expect(hook).to be_valid
        expect(hook.custom_headers).to eq({ test: 'blub' })
      end

      it 'does not reset custom headers if url and url variables changed and evaluate to the same url' do
        hook.url = 'http://example.com/{def}'
        hook.url_variables = { 'def' => 'supers3cret' }

        expect(hook).to be_valid
        expect(hook.custom_headers).to eq({ test: 'blub' })
      end
    end

    it "only consider these branch filter strategies are valid" do
      expected_valid_types = %w[all_branches regex wildcard]
      expect(described_class.branch_filter_strategies.keys).to match_array(expected_valid_types)
    end
  end

  describe 'encrypted attributes' do
    subject { described_class.attr_encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:token, :url, :url_variables, :custom_headers) }
  end

  describe 'execute' do
    let(:data) { { key: 'value' } }
    let(:hook_name) { 'the hook name' }

    it '#execute' do
      expect_next(WebHookService).to receive(:execute)

      hook.execute(data, hook_name)
    end

    it 'passes force: false to the web hook service by default' do
      expect(WebHookService)
        .to receive(:new).with(hook, data, hook_name, idempotency_key: anything,
          force: false).and_return(instance_double(WebHookService, execute: :done))

      expect(hook.execute(data, hook_name)).to eq :done
    end

    it 'passes force: true to the web hook service if required' do
      expect(WebHookService)
        .to receive(:new).with(hook, data, hook_name, idempotency_key: anything,
          force: true).and_return(instance_double(WebHookService, execute: :forced))

      expect(hook.execute(data, hook_name, force: true)).to eq :forced
    end

    it 'forwards the idempotency key to the WebHook service when present' do
      idempotency_key = SecureRandom.uuid

      expect(WebHookService)
        .to receive(:new)
        .with(anything, anything, anything, idempotency_key: idempotency_key, force: anything)
        .and_return(instance_double(WebHookService, execute: :done))

      expect(hook.execute(data, hook_name, idempotency_key: idempotency_key)).to eq :done
    end

    it 'forwards a nil idempotency key to the WebHook service when not supplied' do
      expect(WebHookService)
        .to receive(:new).with(anything, anything, anything, idempotency_key: nil,
          force: anything).and_return(instance_double(WebHookService, execute: :done))

      expect(hook.execute(data, hook_name)).to eq :done
    end
  end

  describe 'async_execute' do
    let(:data) { { key: 'value' } }
    let(:hook_name) { 'the hook name' }

    it '#async_execute' do
      expect_next(WebHookService).to receive(:async_execute)

      hook.async_execute(data, hook_name)
    end

    it 'forwards the idempotency key to the WebHook service when present' do
      idempotency_key = SecureRandom.uuid

      expect(WebHookService)
        .to receive(:new)
        .with(anything, anything, anything, idempotency_key: idempotency_key)
        .and_return(instance_double(WebHookService, async_execute: :done))

      expect(hook.async_execute(data, hook_name, idempotency_key: idempotency_key)).to eq :done
    end

    it 'forwards a nil idempotency key to the WebHook service when not supplied' do
      expect(WebHookService)
        .to receive(:new).with(anything, anything, anything,
          idempotency_key: nil).and_return(instance_double(WebHookService, async_execute: :done))

      expect(hook.async_execute(data, hook_name)).to eq :done
    end

    it 'does not async execute non-executable hooks' do
      allow(hook).to receive(:executable?).and_return(false)

      expect(WebHookService).not_to receive(:new)

      hook.async_execute(data, hook_name)
    end
  end

  describe '#next_backoff' do
    before do
      hook.backoff_count = backoff_count
    end

    context 'when there was no last backoff' do
      let(:backoff_count) { 0 }

      it 'is the initial value' do
        expect(hook.next_backoff).to eq(WebHooks::AutoDisabling::INITIAL_BACKOFF)
      end
    end

    context 'when we have backed off once' do
      let(:backoff_count) { 1 }

      it 'is twice the initial value' do
        expect(hook.next_backoff).to eq(2 * WebHooks::AutoDisabling::INITIAL_BACKOFF)
      end
    end

    context 'when the next backoff is just before the max backoff limit' do
      let(:backoff_count) { WebHooks::AutoDisabling::MAX_BACKOFF_COUNT - 1 }

      it 'is an exponential of the initial backoff' do
        expect(hook.next_backoff).to eq((2**backoff_count) * WebHooks::AutoDisabling::INITIAL_BACKOFF)
      end

      it 'is not yet capped at the max limit' do
        expect(hook.next_backoff).to be < WebHooks::AutoDisabling::MAX_BACKOFF
      end
    end

    describe 'when next_backoff has reached the MAX_BACKOFF limit' do
      let(:backoff_count) { WebHooks::AutoDisabling::MAX_BACKOFF_COUNT }

      it 'does not exceed the max backoff value' do
        expect(hook.next_backoff).to eq(WebHooks::AutoDisabling::MAX_BACKOFF)
      end
    end
  end

  describe '#rate_limited?' do
    it 'is false when hook has not been rate limited' do
      expect_next_instance_of(Gitlab::WebHooks::RateLimiter) do |rate_limiter|
        expect(rate_limiter).to receive(:rate_limited?).and_return(false)
      end

      expect(hook).not_to be_rate_limited
    end

    it 'is true when hook has been rate limited' do
      expect_next_instance_of(Gitlab::WebHooks::RateLimiter) do |rate_limiter|
        expect(rate_limiter).to receive(:rate_limited?).and_return(true)
      end

      expect(hook).to be_rate_limited
    end
  end

  describe '#rate_limit' do
    it 'returns the hook rate limit' do
      expect_next_instance_of(Gitlab::WebHooks::RateLimiter) do |rate_limiter|
        expect(rate_limiter).to receive(:limit).and_return(10)
      end

      expect(hook.rate_limit).to eq(10)
    end
  end

  describe '#to_json' do
    it 'does not error' do
      expect { hook.to_json }.not_to raise_error
    end

    it 'does not contain binary attributes' do
      expect(hook.to_json).not_to include('encrypted_url_variables')
    end
  end

  describe '#interpolated_url' do
    subject(:hook) { build(factory) }

    context 'when the hook URL does not contain variables' do
      before do
        hook.url = 'http://example.com'
      end

      it { is_expected.to have_attributes(interpolated_url: hook.url) }
    end

    it 'is not vulnerable to malicious input' do
      hook.url = 'something%{%<foo>2147483628G}'
      hook.url_variables = { 'foo' => '1234567890.12345678' }

      expect(hook).to have_attributes(interpolated_url: hook.url)
    end

    context 'when the hook URL contains variables' do
      before do
        hook.url = 'http://example.com/{path}/resource?token={token}'
        hook.url_variables = { 'path' => 'abc', 'token' => 'xyz' }
      end

      it { is_expected.to have_attributes(interpolated_url: 'http://example.com/abc/resource?token=xyz') }

      context 'when a variable is missing' do
        before do
          hook.url_variables = { 'path' => 'present' }
        end

        it 'raises an error' do
          # We expect validations to prevent this entirely - this is not user-error
          expect { hook.interpolated_url }
            .to raise_error(described_class::InterpolationError, include('Missing key token'))
        end
      end

      context 'when the URL appears to include percent formatting' do
        before do
          hook.url = 'http://example.com/%{path}/resource?token=%{token}'
        end

        it 'succeeds, interpolates correctly' do
          expect(hook.interpolated_url).to eq 'http://example.com/%abc/resource?token=%xyz'
        end
      end
    end
  end

  describe '#masked_token' do
    it { expect(hook.masked_token).to be_nil }

    context 'with a token' do
      let(:hook) { build(factory, :token) }

      it { expect(hook.masked_token).to eq described_class::SECRET_MASK }
    end
  end

  describe '#backoff!', if: auto_disabling do
    context 'when we have not backed off before' do
      it 'increments the recent_failures count but does not disable the hook yet' do
        expect { hook.backoff! }.to change { hook.recent_failures }.to(1)
        expect(hook.class.executable).to include(hook)
      end
    end

    context 'when hook is at the failure threshold' do
      before do
        WebHooks::AutoDisabling::FAILURE_THRESHOLD.times { hook.backoff! }
      end

      it 'is not yet disabled' do
        expect(hook.class.executable).to include(hook)
        expect(hook).to have_attributes(
          recent_failures: WebHooks::AutoDisabling::FAILURE_THRESHOLD,
          backoff_count: 0,
          disabled_until: nil
        )
      end

      context 'when hook is next told to backoff' do
        before do
          hook.backoff!
        end

        it 'causes the hook to become disabled for initial backoff period' do
          expect(hook.class.executable).not_to include(hook)
          expect(hook).to have_attributes(
            recent_failures: (WebHooks::AutoDisabling::FAILURE_THRESHOLD + 1),
            backoff_count: 1,
            disabled_until: 1.minute.from_now
          )
        end

        context 'when the backoff time has elapsed', :skip_freeze_time do
          it 'is no longer disabled' do
            travel_to(hook.disabled_until + 1.minute) do
              expect(hook.class.executable).to include(hook)
            end
          end

          context 'when the hook is next told to backoff' do
            it 'disables the hook again, increasing the backoff time exponentially' do
              travel_to(hook.disabled_until + 1.minute) do
                hook.backoff!

                expect(hook.class.executable).not_to include(hook)
                expect(hook).to have_attributes(
                  recent_failures: (WebHooks::AutoDisabling::FAILURE_THRESHOLD + 2),
                  backoff_count: 2,
                  disabled_until: 2.minutes.from_now
                )
              end
            end
          end
        end
      end
    end

    it 'does not do anything if the hook is currently temporarily disabled' do
      allow(hook).to receive(:temporarily_disabled?).and_return(true)

      sql_count = ActiveRecord::QueryRecorder.new { hook.backoff! }.count

      expect(sql_count).to eq(0)
    end

    it 'does not do anything if the hook is currently permanently disabled' do
      allow(hook).to receive(:permanently_disabled?).and_return(true)

      sql_count = ActiveRecord::QueryRecorder.new { hook.backoff! }.count

      expect(sql_count).to eq(0)
    end

    context 'when the counter are above MAX_FAILURES' do
      let(:max_failures) { WebHooks::AutoDisabling::MAX_FAILURES }

      before do
        hook.update!(
          recent_failures: (max_failures + 1),
          backoff_count: (max_failures + 1),
          disabled_until: 1.hour.ago
        )
      end

      it 'reduces the counter to MAX_FAILURES' do
        hook.backoff!

        expect(hook).to have_attributes(
          recent_failures: max_failures,
          backoff_count: max_failures
        )
      end
    end
  end

  describe '#failed!', if: auto_disabling do
    it 'increments the recent_failures count but does not disable the hook yet' do
      expect { hook.failed! }.to change { hook.recent_failures }.to(1)
      expect(hook.class.executable).to include(hook)
    end

    context 'when hook is at the failure threshold' do
      before do
        WebHooks::AutoDisabling::FAILURE_THRESHOLD.times { hook.failed! }
      end

      it 'is not yet disabled' do
        expect(hook.class.executable).to include(hook)
        expect(hook).to have_attributes(
          recent_failures: WebHooks::AutoDisabling::FAILURE_THRESHOLD,
          backoff_count: 0,
          disabled_until: nil
        )
      end

      context 'when hook is next failed' do
        before do
          hook.failed!
        end

        it 'causes the hook to become disabled' do
          expect(hook.class.executable).not_to include(hook)
          expect(hook).to have_attributes(
            recent_failures: (WebHooks::AutoDisabling::FAILURE_THRESHOLD + 1),
            backoff_count: 0,
            disabled_until: nil
          )
        end
      end
    end

    it 'does not do anything if recent_failures is at MAX_FAILURES' do
      hook.recent_failures = WebHooks::AutoDisabling::MAX_FAILURES

      sql_count = ActiveRecord::QueryRecorder.new { hook.failed! }.count

      expect(sql_count).to eq(0)
    end
  end
end
