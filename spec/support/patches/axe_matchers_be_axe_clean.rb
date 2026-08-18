# frozen_string_literal: true

# GitLab-local extensions to the axe-core-rspec `be_axe_clean` matcher.
#
# IMPORTANT: none of this is a feature of axe-core-rspec. The gem's matcher
# (Axe::Matchers::BeAxeClean) only supports the chainable clauses `within`,
# `excluding`, `according_to`, `checking`, `checking_only`, `skipping`, and
# `with_options`, and it fails on *any* violation regardless of severity
# (Axe::API::Audit#passed? is literally `results.violations.count == 0`).
#
# We deliberately monkey-patch the gem here by `prepend`ing the modules below.
# `prepend` keeps every gem clause intact (we never redefine them) and lets our
# overrides fall back to the gem via `super`. The wiring is at the bottom of the
# file so it is obvious what we add and where.
module Accessibility
  module Patches
    # We have a rubocop rule to enforce the use of the `within_testid` feature
    # spec helper, but it does not work with the `be_axe_clean` matcher. This
    # adds `within_testid` support to the matcher.
    module AxeTestidSupport
      def within_testid(testid)
        within("[data-testid=\"#{testid}\"]")
      end
    end

    # Adds severity ("impact") filtering, which axe-core-rspec does not provide.
    # A check fails only on violations whose impact is at or above the requested
    # threshold; less severe violations are ignored. Filtering is strictly
    # opt-in per spec via `with_minimum_impact`: with no clause, the matcher
    # behaves exactly like the gem (fail on any violation).
    module AxeImpactFilter
      # Axe severity ladder, lowest to highest. A violation fails a check when
      # its impact is at or above the requested minimum.
      IMPACT_LEVELS = %i[minor moderate serious critical].freeze

      # Fail only on violations whose impact is at or above `level`. Intended as a
      # getting-started clause for teams adding coverage to an area for the first
      # time, for example:
      #
      #   expect(page).to be_axe_clean.within('#content-body').with_minimum_impact(
      #     :critical, because: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345 - bootstrapping coverage'
      #   )
      #
      # `because:` is required and must be non-blank. Relaxing the threshold hides
      # real violations, so every use must carry a human-readable reason (ideally a
      # tracking issue link) at the call site. We do not store or act on the reason:
      # its whole job is to be visible in the diff, `git blame`, and `grep`, and to
      # give code review something concrete to push back on. Enforcing that the
      # reason is *good* is review's job, not this matcher's.
      #
      # Validates eagerly here (rather than while filtering violations) so a typo or
      # a missing reason fails fast at the call site, even when the page has no
      # violations. Returns self so it can be chained like the gem's own clauses.
      def with_minimum_impact(level, because:)
        unless IMPACT_LEVELS.include?(level)
          raise ArgumentError,
            "Unknown axe impact level: #{level.inspect}. Pass one of these symbols: " \
              "#{IMPACT_LEVELS.map(&:inspect).join(', ')}"
        end

        if @minimum_impact
          raise ArgumentError,
            "with_minimum_impact was already called with #{@minimum_impact.inspect}. Chain it only once per check."
        end

        if because.to_s.strip.empty?
          raise ArgumentError,
            'with_minimum_impact requires a non-blank `because:` reason explaining why coverage is ' \
              'relaxed (ideally a tracking issue link), for example: with_minimum_impact(:critical, ' \
              "because: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345 - bootstrapping coverage')."
        end

        @minimum_impact = level
        @minimum_impact_reason = because
        self
      end

      def matches?(page)
        # No per-spec threshold: defer to the gem's default (fail on any violation).
        return super unless @minimum_impact

        violations = audit(page).results.violations.select do |violation|
          impact_at_least?(violation.impact, @minimum_impact)
        end
        violations.empty?
      end

      # When a threshold is set, prepend a one-line notice to the gem's own
      # report, then delegate the body to the gem via `super`. We deliberately
      # show the gem's full, unfiltered report (every violation, all severities)
      # rather than reformatting it: the check only *fails* on violations at or
      # above @minimum_impact (see `matches?`), but listing the lower-severity
      # ones too gives the team the full picture and avoids coupling to the gem's
      # private message formatting.
      # NOTE: only the positive path is customized; `failure_message_when_negated`
      # (used by `not_to be_axe_clean`) still falls through to the gem unchanged.
      def failure_message
        # No threshold applied: use the gem's own failure message unchanged.
        return super unless @minimum_impact

        "#{minimum_impact_notice}\n#{super}"
      end

      private

      def minimum_impact_notice
        "NOTE: this check fails only on violations with impact `#{@minimum_impact}` or higher " \
          "(levels, lowest to highest: #{IMPACT_LEVELS.join(', ')}). " \
          "Lower-severity violations may also be listed below for context but did not fail the check.\n" \
          "Reason given for relaxing this check: #{@minimum_impact_reason}"
      end

      # `threshold` is already validated by `with_minimum_impact`, so its index is
      # always present. The gem coerces `impact` to a Symbol (Virtus attribute),
      # but we call `to_sym` defensively.
      #
      # We fail closed: an unknown or nil impact is treated as at or above any
      # threshold so it always surfaces. A threshold is meant to relax only the
      # severities we understand; a violation axe could not classify must never be
      # silently hidden by opting into filtering.
      def impact_at_least?(impact, threshold)
        index = IMPACT_LEVELS.index(impact&.to_sym)
        return true if index.nil?

        index >= IMPACT_LEVELS.index(threshold)
      end
    end
  end
end

Axe::Matchers::BeAxeClean.prepend(Accessibility::Patches::AxeTestidSupport)
Axe::Matchers::BeAxeClean.prepend(Accessibility::Patches::AxeImpactFilter)
