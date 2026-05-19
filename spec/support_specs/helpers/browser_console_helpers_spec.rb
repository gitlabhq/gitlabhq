# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../support/helpers/browser_console_helpers'

RSpec.describe BrowserConsoleHelpers, feature_category: :tooling do
  describe 'BROWSER_CONSOLE_FILTER' do
    subject(:filter) { described_class::BROWSER_CONSOLE_FILTER }

    where(:message) do
      [
        # rubocop:disable Layout/LineLength -- full length strings added for testing

        ['[vite] connecting...'],
        ['[vite] connected.'],
        ['The resource http://127.0.0.1/assets/font.woff2 was preloaded using link preload but not used'],

        # Matches https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/blob/17786d0c663104988603e59c7881309a729c6bdd/packages/gitlab-ui/src/config.js
        ['[@gitlab/ui] The following translations have not been given, so will fall back to their default US English strings:'],
        # Matches https://gitlab.com/gitlab-org/duo-ui/-/blob/171be4be1952b65939aa622879c68347bb7c552d/src/config.js
        ['[@gitlab/duo-ui] The following translations have not been given, so will fall back to their default US English strings:']

        # rubocop:enable Layout/LineLength
      ]
    end

    with_them do
      it 'matches the console message' do
        expect(message).to match(filter)
      end
    end

    context 'with unrelated messages' do
      where(:message) do
        [
          ['Some unrelated console message'],
          ['INFO: application started']
        ]
      end

      with_them do
        it 'does not match the console message' do
          expect(message).not_to match(filter)
        end
      end
    end
  end
end
