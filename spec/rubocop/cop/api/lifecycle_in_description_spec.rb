# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/lifecycle_in_description'

RSpec.describe RuboCop::Cop::API::LifecycleInDescription, :config, feature_category: :api do
  let(:msg) do
    'Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. ' \
      'Use `route_setting :lifecycle, :experiment` or `route_setting :lifecycle, :beta` instead. ' \
      'https://docs.gitlab.com/development/api_styleguide/#marking-endpoint-lifecycle'
  end

  context 'when detail contains lifecycle terms' do
    it 'registers an offense for experimental in detail' do
      expect_offense(<<~RUBY)
        desc 'Get all widgets' do
          detail 'This feature is experimental.'
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          tags %w[widgets]
        end
      RUBY
    end

    it 'registers an offense for experiment in detail' do
      expect_offense(<<~RUBY)
        desc 'Get all widgets' do
          detail 'This is an experiment.'
                 ^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          tags %w[widgets]
        end
      RUBY
    end

    it 'registers an offense for beta in detail' do
      expect_offense(<<~RUBY)
        desc 'Get all widgets' do
          detail 'This feature is in beta.'
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          tags %w[widgets]
        end
      RUBY
    end

    it 'registers an offense for case-insensitive match' do
      expect_offense(<<~RUBY)
        desc 'Get all widgets' do
          detail 'This feature is EXPERIMENTAL.'
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          tags %w[widgets]
        end
      RUBY
    end

    it 'registers an offense for concatenated detail string' do
      expect_offense(<<~RUBY)
        desc 'Get all widgets' do
          detail 'This feature is currently in an experimental state. ' \\
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
            'Updates the confidence score.'
          tags %w[widgets]
        end
      RUBY
    end
  end

  context 'when desc summary contains lifecycle terms' do
    it 'registers an offense for experimental in summary' do
      expect_offense(<<~RUBY)
        desc '[EXPERIMENTAL] Get all widgets' do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          detail 'Introduced in GitLab 18.10.'
          tags %w[widgets]
        end
      RUBY
    end

    it 'registers an offense for beta in summary' do
      expect_offense(<<~RUBY)
        desc '[BETA] Get all widgets' do
             ^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          detail 'Introduced in GitLab 18.10.'
          tags %w[widgets]
        end
      RUBY
    end
  end

  context 'when both summary and detail contain lifecycle terms' do
    it 'registers offenses for both' do
      expect_offense(<<~RUBY)
        desc '[EXPERIMENTAL] Get all widgets' do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          detail 'This feature is experimental.'
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          tags %w[widgets]
        end
      RUBY
    end
  end

  context 'when desc block does not contain lifecycle terms' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc 'Get all widgets' do
          detail 'Introduced in GitLab 18.10.'
          tags %w[widgets]
        end
      RUBY
    end

    it 'does not register an offense with route_setting lifecycle' do
      expect_no_offenses(<<~RUBY)
        route_setting :lifecycle, :experiment
        desc 'Get all widgets' do
          detail 'Introduced in GitLab 18.10.'
          tags %w[widgets]
        end
      RUBY
    end

    it 'does not register an offense for deprecated detail' do
      expect_no_offenses(<<~RUBY)
        desc 'Get all widgets' do
          detail 'Deprecated in GitLab 17.0.'
          deprecated true
          tags %w[widgets]
        end
      RUBY
    end
  end

  context 'when desc block only contains detail' do
    it 'registers an offense for lifecycle term in detail' do
      expect_offense(<<~RUBY)
        desc 'Get all widgets' do
          detail 'This feature is experimental.'
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
        end
      RUBY
    end

    it 'does not register an offense when detail has no lifecycle term' do
      expect_no_offenses(<<~RUBY)
        desc 'Get all widgets' do
          detail 'Introduced in GitLab 18.10.'
        end
      RUBY
    end
  end

  context 'when summary uses string interpolation' do
    it 'does not register an offense for interpolation without lifecycle terms' do
      expect_no_offenses(<<~'RUBY')
        desc "Get all #{resource} widgets" do
          detail 'Introduced in GitLab 18.10.'
          tags %w[widgets]
        end
      RUBY
    end

    it 'registers an offense for interpolation with lifecycle terms' do
      expect_offense(<<~'RUBY')
        desc "Get all experimental #{resource} widgets" do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. [...]
          detail 'Introduced in GitLab 18.10.'
          tags %w[widgets]
        end
      RUBY
    end
  end

  context 'when a non-desc block is used' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :id, type: String, desc: 'This is experimental'
        end
      RUBY
    end
  end

  context 'when desc is called without a block' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc 'This feature is experimental'
      RUBY
    end
  end

  context 'when desc is called on an object' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        object.desc 'This feature is experimental' do
          detail 'This feature is experimental.'
        end
      RUBY
    end
  end
end
