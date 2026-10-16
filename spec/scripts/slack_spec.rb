# frozen_string_literal: true

require 'fast_spec_helper'
require 'open3'
require 'rspec-parameterized'
require 'tmpdir'

RSpec.describe 'scripts/slack', feature_category: :tooling do
  let(:script) { File.expand_path('../../scripts/slack', __dir__) }
  let(:webhook_url) { 'https://hooks.example.test/webhook' }
  let(:message) { 'job failed' }
  let(:icon_emoji) { 'ci_failing' }
  let(:username) { 'GitLab Bot' }

  # A stand-in for curl that records its arguments, so no request leaves the machine.
  let(:fake_curl) do
    <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > "$CURL_ARGS_FILE"
    SH
  end

  def run_script(*args, env: { 'CI_SLACK_WEBHOOK_URL' => webhook_url })
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'curl'), fake_curl)
      File.chmod(0o755, File.join(dir, 'curl'))
      args_file = File.join(dir, 'curl_args')

      full_env = { 'PATH' => "#{dir}:#{ENV.fetch('PATH')}", 'CURL_ARGS_FILE' => args_file }.merge(env)
      output, status = Open3.capture2e(full_env, script, *args)
      curl_args = File.exist?(args_file) ? File.readlines(args_file, chomp: true) : nil

      [output, status, curl_args]
    end
  end

  def posted_payload(curl_args)
    Gitlab::Json::SafeParser.parse(curl_args.find { |arg| arg.start_with?('payload=') }.delete_prefix('payload='))
  end

  describe 'channel target' do
    where(:channel, :expected_target) do
      [
        ['master-broken', '#master-broken'],
        ['g_pipeline-authoring_alerts', '#g_pipeline-authoring_alerts'],
        ['CR6QH3D7C', 'CR6QH3D7C'],
        ['C0123456789', 'C0123456789'],
        ['G0123456789', 'G0123456789'],
        # Too short to be an ID, so it is treated as a name.
        ['CABC', '#CABC'],
        # Starts with neither C nor G.
        ['D0123456789', '#D0123456789'],
        # Lowercase never counts as an ID.
        ['c0123456789', '#c0123456789']
      ]
    end

    with_them do
      it 'posts to the expected target' do
        _output, status, curl_args = run_script(channel, message, icon_emoji, username)

        expect(status).to be_success
        expect(posted_payload(curl_args)).to include('channel' => expected_target)
      end
    end
  end

  it 'posts the message, username, and icon to the webhook' do
    _output, _status, curl_args = run_script('master-broken', message, icon_emoji, username)

    expect(curl_args).to include(webhook_url)
    expect(posted_payload(curl_args)).to eq(
      'channel' => '#master-broken',
      'username' => username,
      'text' => message,
      'icon_emoji' => ":#{icon_emoji}:"
    )
  end

  context 'when an argument is missing' do
    it 'does not post and prints the usage' do
      output, _status, curl_args = run_script('master-broken', message, icon_emoji)

      expect(curl_args).to be_nil
      expect(output).to include('Missing argument(s)')
    end
  end

  context 'when CI_SLACK_WEBHOOK_URL is not set' do
    it 'does not post and prints the usage' do
      output, _status, curl_args = run_script(
        'CR6QH3D7C', message, icon_emoji, username, env: { 'CI_SLACK_WEBHOOK_URL' => nil }
      )

      expect(curl_args).to be_nil
      expect(output).to include('Missing argument(s)')
    end
  end
end
