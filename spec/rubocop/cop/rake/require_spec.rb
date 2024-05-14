# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rake/require'

RSpec.describe RuboCop::Cop::Rake::Require do
  let(:msg) { described_class::MSG }

  describe '#in_rake_file?' do
    context 'in a Rake file' do
      let(:node) { double(location: double(expression: double(source_buffer: double(name: 'foo/bar.rake')))) } # rubocop:disable RSpec/VerifiedDoubles

      it { expect(subject.__send__(:in_rake_file?, node)).to be(true) }
    end

    context 'when outside of a Rake file' do
      let(:node) { double(location: double(expression: double(source_buffer: double(name: 'foo/bar.rb')))) } # rubocop:disable RSpec/VerifiedDoubles

      it { expect(subject.__send__(:in_rake_file?, node)).to be(false) }
    end
  end

  context 'in a Rake file' do
    before do
      allow(cop).to receive(:in_rake_file?).and_return(true)
    end

    it 'registers offenses for require methods' do
      expect_offense(<<~RUBY)
        require 'json'
        ^^^^^^^^^^^^^^ #{msg}
        require_relative 'gitlab/json'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offenses for require methods inside `namespace` definitions' do
      expect_offense(<<~RUBY)
        namespace :foo do
          require 'json'
          ^^^^^^^^^^^^^^ #{msg}

          task :parse do
          end
        end

        namespace :bar do
          require_relative 'gitlab/json'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}

          task :parse do
          end
        end
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

        def self.run
          require 'yaml'
        end

        task :parse do
          load_deps
          run
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

  context 'when outside of a Rake file' do
    before do
      allow(cop).to receive(:in_rake_file?).and_return(false)
    end

    it 'registers an offenses for require methods' do
      expect_no_offenses("require 'json'")
    end
  end
end
