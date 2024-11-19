# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/outdated_todo'

RSpec.describe Tooling::Danger::OutdatedTodo, feature_category: :tooling do
  let(:fake_danger) { double }
  let(:filenames) { ['app/controllers/application_controller.rb'] }

  let(:todos) do
    [
      File.join('spec', 'fixtures', 'tooling', 'danger', 'rubocop_todo', '**', '*.yml'),
      File.join('spec', 'fixtures', 'tooling', 'danger', 'rspec_order_todo.yml')
    ]
  end

  subject(:plugin) { described_class.new(filenames, context: fake_danger, todos: todos, allow_fail: allow_fail) }

  shared_examples 'no warning' do
    it 'does not warn' do
      expect(fake_danger).not_to receive(expected_method)

      plugin.check
    end
  end

  [true, false].each do |allow_failure|
    context "with allow_fail set to #{allow_failure}" do
      let(:allow_fail) { allow_failure }
      let(:expected_method) do
        allow_failure ? :fail : :warn
      end

      context 'when the filenames are mentioned in single todo' do
        let(:filenames) { ['app/controllers/acme_challenges_controller.rb'] }

        it 'warns about mentions' do
          expect(fake_danger)
            .to receive(expected_method)
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
            'app/controllers/acme_challenges_controller.rb',
            'ee/app/models/epic.rb'
          ]
        end

        it 'warns about mentions' do
          expect(fake_danger)
            .to receive(expected_method)
            .with(<<~MESSAGE)
              `app/controllers/application_controller.rb` was removed but is mentioned in:
              - `spec/fixtures/tooling/danger/rubocop_todo/cop1.yml:4`
              - `spec/fixtures/tooling/danger/rubocop_todo/cop2.yml:4`
            MESSAGE

          expect(fake_danger)
            .to receive(expected_method)
            .with(<<~MESSAGE)
              `app/controllers/acme_challenges_controller.rb` was removed but is mentioned in:
              - `spec/fixtures/tooling/danger/rubocop_todo/cop1.yml:5`
            MESSAGE

          expect(fake_danger)
            .to receive(expected_method)
            .with(<<~MESSAGE)
              `ee/app/models/epic.rb` was removed but is mentioned in:
              - `spec/fixtures/tooling/danger/rubocop_todo/cop1.yml:6`
              - `spec/fixtures/tooling/danger/rspec_order_todo.yml:3`
            MESSAGE

          plugin.check
        end
      end

      context 'when EE filesnames are mentioned in multiple todos' do
        let(:filenames) do
          [
            'app/models/epic.rb'
          ]
        end

        it_behaves_like 'no warning'
      end

      context 'when the filenames are not mentioned in todos' do
        let(:filenames) { ['any/inexisting/file.rb'] }

        it_behaves_like 'no warning'
      end

      context 'when there is no todos' do
        let(:filenames) { ['app/controllers/acme_challenges_controller.rb'] }
        let(:todos) { [] }

        it_behaves_like 'no warning'
      end
    end
  end
end
