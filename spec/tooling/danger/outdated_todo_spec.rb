# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/outdated_todo'

RSpec.describe Tooling::Danger::OutdatedTodo, feature_category: :tooling do
  let(:fake_danger) { double }
  let(:filenames) { ['app/controllers/application_controller.rb'] }

  let(:todos) do
    [
      File.join('spec', 'fixtures', 'tooling', 'danger', 'rubocop_todo', '**', '*.yml')
    ]
  end

  subject(:plugin) { described_class.new(filenames, context: fake_danger, todos: todos) }

  context 'when the filenames are mentioned in single todo' do
    let(:filenames) { ['app/controllers/acme_challenges_controller.rb'] }

    it 'warns about mentions' do
      expect(fake_danger)
        .to receive(:warn)
        .with <<~MESSAGE
          `app/controllers/acme_challenges_controller.rb` was removed but is mentioned in:
          - `spec/fixtures/tooling/danger/rubocop_todo/cop1.yml:5`
        MESSAGE

      plugin.check
    end
  end

  context 'when the filenames are mentioned in multiple todos' do
    let(:filenames) do
      [
        'app/controllers/application_controller.rb',
        'app/controllers/acme_challenges_controller.rb'
      ]
    end

    it 'warns about mentions' do
      expect(fake_danger)
        .to receive(:warn)
        .with(<<~FIRSTMESSAGE)
          `app/controllers/application_controller.rb` was removed but is mentioned in:
          - `spec/fixtures/tooling/danger/rubocop_todo/cop1.yml:4`
          - `spec/fixtures/tooling/danger/rubocop_todo/cop2.yml:4`
        FIRSTMESSAGE

      expect(fake_danger)
        .to receive(:warn)
        .with(<<~SECONDMESSAGE)
          `app/controllers/acme_challenges_controller.rb` was removed but is mentioned in:
          - `spec/fixtures/tooling/danger/rubocop_todo/cop1.yml:5`
        SECONDMESSAGE

      plugin.check
    end
  end

  context 'when the filenames are not mentioned in todos' do
    let(:filenames) { ['any/inexisting/file.rb'] }

    it 'does not warn' do
      expect(fake_danger).not_to receive(:warn)

      plugin.check
    end
  end

  context 'when there is no todos' do
    let(:filenames) { ['app/controllers/acme_challenges_controller.rb'] }
    let(:todos) { [] }

    it 'does not warn' do
      expect(fake_danger).not_to receive(:warn)

      plugin.check
    end
  end
end
