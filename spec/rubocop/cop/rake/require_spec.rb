# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rake/require'

RSpec.describe RuboCop::Cop::Rake::Require do
  let(:msg) { described_class::MSG }

  it 'registers an offenses for require methods' do
    expect_offense(<<~RUBY)
      require 'json'
      ^^^^^^^^^^^^^^ #{msg}
      require_relative 'gitlab/json'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end

  it 'does not register offense inside `task` definition' do
    expect_no_offenses(<<~RUBY)
      task :parse do
        require 'json'
      end

      namespace :some do
        task parse: :env do
          require_relative 'gitlab/json'
        end
      end
    RUBY
  end

  it 'does not register offense inside a block definition' do
    expect_no_offenses(<<~RUBY)
      RSpec::Core::RakeTask.new(:parse_json) do |t, args|
        require 'json'
      end
    RUBY
  end

  it 'does not register offense inside a method definition' do
    expect_no_offenses(<<~RUBY)
      def load_deps
        require 'json'
      end

      task :parse do
        load_deps
      end
    RUBY
  end

  it 'does not register offense when require task related files' do
    expect_no_offenses(<<~RUBY)
      require 'rubocop/rake_tasks'
      require 'gettext_i18n_rails/tasks'
      require_relative '../../rubocop/check_graceful_task'
    RUBY
  end
end
