# frozen_string_literal: true

require 'fast_spec_helper'
require 'axe-rspec'
require 'axe/api/audit'
require 'axe/api/results'
require 'axe/api/results/rule'
require 'axe/core'
require 'capybara'

require File.expand_path('../../support/patches/axe_matchers_be_axe_clean.rb', __dir__)

RSpec.describe 'be_axe_clean matcher patch', feature_category: :tooling do
  subject(:matcher) { Axe::Matchers::BeAxeClean.new }

  let(:page) { instance_double(Capybara::Session) }
  let(:reason) { 'bootstrapping coverage; tracked in issue 12345' }

  def violation(impact)
    instance_double(Axe::API::Results::Rule, impact: impact)
  end

  def stub_audit(violations)
    results = instance_double(Axe::API::Results, violations: violations)
    audit = instance_double(
      Axe::API::Audit,
      results: results,
      passed?: violations.empty?,
      failure_message: 'gem failure message'
    )

    # Stub only the real boundary: Axe::Core#call is what runs the axe-core
    # JavaScript in a browser (the gem's `audit` is `@audit ||= Core.new(page).call(@run)`).
    # Letting the gem's own `audit` run then memoizes the result into @audit, so
    # matches? and failure_message (which delegates via `def_delegators :@audit`)
    # exercise the real gem path without us stubbing gem methods or poking @audit.
    allow(Axe::Core).to receive(:new).with(page).and_return(instance_double(Axe::Core, call: audit))
  end

  describe '#within_testid' do
    it 'delegates to within with a data-testid selector' do
      expect(matcher).to receive(:within).with('[data-testid="my-id"]')
      matcher.within_testid('my-id')
    end
  end

  describe '#matches?' do
    context 'without a threshold (default behavior)' do
      it 'fails on any violation regardless of severity' do
        stub_audit([violation(:moderate)])

        expect(matcher.matches?(page)).to be(false)
      end

      it 'passes when there are no violations' do
        stub_audit([])

        expect(matcher.matches?(page)).to be(true)
      end
    end

    context 'with a per-spec minimum impact of :critical' do
      it 'passes when only lower-severity violations exist' do
        stub_audit([violation(:serious), violation(:moderate)])

        expect(matcher.with_minimum_impact(:critical, because: reason).matches?(page)).to be(true)
      end

      it 'fails when a critical violation exists' do
        stub_audit([violation(:critical), violation(:serious)])

        expect(matcher.with_minimum_impact(:critical, because: reason).matches?(page)).to be(false)
      end

      it 'fails closed on a violation with no impact so it is never silently hidden' do
        stub_audit([violation(nil)])

        expect(matcher.with_minimum_impact(:critical, because: reason).matches?(page)).to be(false)
      end
    end

    context 'with a per-spec minimum impact of :serious' do
      it 'ignores moderate violations' do
        stub_audit([violation(:moderate)])

        expect(matcher.with_minimum_impact(:serious, because: reason).matches?(page)).to be(true)
      end

      it 'fails on serious violations' do
        stub_audit([violation(:serious)])

        expect(matcher.with_minimum_impact(:serious, because: reason).matches?(page)).to be(false)
      end
    end

    context 'with an unknown impact level' do
      it 'raises ArgumentError at the with_minimum_impact call site, before any audit runs' do
        expect { matcher.with_minimum_impact(:catastrophic, because: reason) }
          .to raise_error(
            ArgumentError,
            'Unknown axe impact level: :catastrophic. Pass one of these symbols: ' \
              ':minor, :moderate, :serious, :critical'
          )
      end

      it 'quotes a String argument so it is not confused with the valid Symbol levels' do
        expect { matcher.with_minimum_impact('critical', because: reason) }
          .to raise_error(
            ArgumentError,
            'Unknown axe impact level: "critical". Pass one of these symbols: ' \
              ':minor, :moderate, :serious, :critical'
          )
      end
    end

    context 'without a `because:` reason' do
      it 'raises ArgumentError when the reason is blank', :aggregate_failures do
        expect { matcher.with_minimum_impact(:critical, because: '') }
          .to raise_error(ArgumentError, /requires a non-blank `because:` reason/)
        expect { matcher.with_minimum_impact(:critical, because: '   ') }
          .to raise_error(ArgumentError, /requires a non-blank `because:` reason/)
      end
    end

    context 'when with_minimum_impact is chained more than once' do
      it 'raises ArgumentError instead of silently overwriting the earlier threshold' do
        matcher.with_minimum_impact(:critical, because: reason)

        expect { matcher.with_minimum_impact(:minor, because: 'a different reason') }
          .to raise_error(
            ArgumentError,
            'with_minimum_impact was already called with :critical. Chain it only once per check.'
          )
      end
    end
  end

  describe 'gem chainable clauses' do
    it 'prepends the GitLab extensions without replacing the gem class', :aggregate_failures do
      ancestors = Axe::Matchers::BeAxeClean.ancestors
      gem_class_index = ancestors.index(Axe::Matchers::BeAxeClean)

      expect(ancestors.index(Accessibility::Patches::AxeImpactFilter)).to be < gem_class_index
      expect(ancestors.index(Accessibility::Patches::AxeTestidSupport)).to be < gem_class_index
    end

    it 'still responds to every gem clause', :aggregate_failures do
      %i[within excluding according_to checking checking_only skipping with_options].each do |clause|
        expect(matcher).to respond_to(clause)
      end
    end

    it 'keeps the gem clauses chainable and returning the matcher', :aggregate_failures do
      expect(matcher.within('#content')).to be(matcher)
      expect(matcher.excluding('#footer')).to be(matcher)
      expect(matcher.according_to(:wcag2a)).to be(matcher)
    end

    it 'returns the matcher from with_minimum_impact so it chains like a gem clause' do
      expect(matcher.with_minimum_impact(:critical, because: reason)).to be(matcher)
    end

    it 'applies the impact threshold when with_minimum_impact is chained after a gem clause' do
      stub_audit([violation(:serious), violation(:moderate)])
      expect(matcher.within('#content-body').with_minimum_impact(:critical, because: reason).matches?(page)).to be(true)
    end

    it 'applies the impact threshold and fails when a critical violation exists, ' \
      'even when chained after a gem clause' do
      stub_audit([violation(:critical)])
      expect(matcher.within('#content-body').with_minimum_impact(:critical,
        because: reason).matches?(page)).to be(false)
    end
  end

  describe '#failure_message' do
    it 'prepends a notice about the threshold and keeps the full gem report', :aggregate_failures do
      stub_audit([violation(:critical), violation(:moderate)])
      matcher.with_minimum_impact(:critical, because: reason).matches?(page)

      message = matcher.failure_message

      expect(message).to include('impact `critical` or higher')
      expect(message).to include('minor, moderate, serious, critical')
      expect(message).to include("Reason given for relaxing this check: #{reason}")
      # The gem report (delegated via `super`) is shown unfiltered, so even the
      # below-threshold violations remain visible for context.
      expect(message).to include('gem failure message')
    end

    it 'delegates to the gem message when no threshold is applied' do
      stub_audit([violation(:moderate)])
      matcher.matches?(page)

      expect(matcher.failure_message).to eq('gem failure message')
    end
  end
end
