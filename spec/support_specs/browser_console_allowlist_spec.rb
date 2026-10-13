# frozen_string_literal: true

require 'fast_spec_helper'
require 'yaml'
require_relative '../support/helpers/browser_console_helpers'

RSpec.describe 'spec/support/browser_console_allowlist.yml', feature_category: :tooling do
  root = File.expand_path('../..', __dir__)
  entries = YAML.safe_load_file(BrowserConsoleHelpers::BROWSER_CONSOLE_ALLOWLIST_PATH)
  allowed_keys = %w[message messages issue specs]

  it 'is a list of entries' do
    expect(entries).to be_an(Array)
    expect(entries).to all(be_a(Hash))
  end

  it 'has no duplicate messages' do
    messages = entries.map { |entry| entry['message'] || entry['messages'] }

    expect(messages).to eq(messages.uniq)
  end

  entries.each do |entry|
    describe "entry #{(entry['message'] || entry['messages']).inspect}" do
      it 'has only allowed keys' do
        expect(entry.keys - allowed_keys).to be_empty
      end

      it 'has either a plain text message or a list of messages' do
        if entry.key?('messages')
          expect(entry).not_to have_key('message')
          expect(entry['messages']).to be_an(Array).and all(be_a(String))
          expect(entry['messages'].size).to be > 1
        else
          expect(entry['message']).to be_a(String)
        end
      end

      it 'has a full issue URL when an issue is set' do
        expect(entry['issue']).to match(%r{\Ahttps://gitlab\.com/.+/-/(issues|work_items)/\d+\z}) if entry.key?('issue')
      end

      it 'scopes to spec files that exist' do
        expect(entry['specs']).to be_an(Array), '`specs` is required; an unscoped entry hides the error on every page'
        expect(entry['specs']).not_to be_empty

        entry['specs'].each do |glob|
          # The as-if-FOSS pipeline removes the ee/ directory.
          next if glob.start_with?('ee/') && !File.directory?(File.join(root, 'ee'))

          matches = Dir.glob(File.join(root, glob))
          expect(matches).not_to be_empty, "`#{glob}` matches no spec file; remove it from the entry"
        end
      end
    end
  end
end
