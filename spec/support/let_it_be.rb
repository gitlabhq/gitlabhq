# frozen_string_literal: true

TestProf::LetItBe.configure do |config|
  config.default_modifiers[:freeze] = true

  config.alias_to :let_it_be_with_refind, refind: true, freeze: false
  config.alias_to :let_it_be_with_reload, reload: true, freeze: false
end

# Patch test-prof's Freezer.deep_freeze to be defensive when walking
# ActiveRecord reflections. The upstream implementation calls
# `record.association(name)` for every reflection on the record's class,
# which triggers `check_validity!`. Several upstream behaviours bite us:
#
#   1. Models with a declared `inverse_of:` that points to a non-existent
#      reflection on the parent raise `InverseOfAssociationNotFoundError`.
#   2. Cyclic association graphs and pathological `let_it_be` factory
#      hierarchies blow the call stack with `SystemStackError` deep in
#      `record.exec_queries` or `record.each` recursion.
#   3. Some models declare `has_many :through` associations in the wrong
#      order, raising `HasManyThroughOrderError`.
#   4. Stale `class_name:` references to constants that no longer exist
#      raise `NameError` ("Missing model class X for the Y#Z association").
#   4b. Composite-primary-key associations (e.g. IssueStageEvent#award_emoji)
#      that cannot be joined raise `CompositePrimaryKeyMismatchError`.
#   5. `Gitlab::View::Presenter::Delegated` is a SimpleDelegator that
#      forwards `is_a?(ActiveRecord::Base)` to its wrapped object but
#      whose own class does not define `.reflections`.
#
# Without intervention, any of these abort the freeze operation entirely,
# even though they only affect one branch of the association tree. We:
#
#   - Always freeze the top-level record first (catches the direct
#     mutation patterns we care about: `subject.update!` etc.).
#   - Rescue the four reflection-walking exceptions per-reflection so
#     traversal continues past one bad branch.
#   - Rescue `SystemStackError` at the recursion entry-point so a deep
#     factory hierarchy does not abort the whole freeze.
#   - Skip non-AR delegating classes (presenters) outright.
#
# Each unique (model class, reflection) pair is warned about once per
# process so a fresh latent bug surfaces in the logs without flooding them.
module TestProf
  module LetItBe
    module Freezer
      RESCUABLE_REFLECTION_ERRORS = [
        ::ActiveRecord::InverseOfAssociationNotFoundError,
        ::ActiveRecord::HasManyThroughOrderError,
        # Composite-PK associations (e.g. IssueStageEvent#award_emoji) that
        # the reflection walk cannot join raise this; skip that branch.
        ::ActiveRecord::CompositePrimaryKeyMismatchError,
        NameError,
        SystemStackError,
        # delegate_missing_to + memoized backing object: respond_to? on
        # the frozen record triggers `@var ||= ...` assignment.
        FrozenError
      ].freeze

      WARNED_REFLECTIONS = Set.new
      WARNED_REFLECTIONS_MUTEX = Mutex.new

      class << self
        def deep_freeze(record)
          return if record.frozen?
          return if Stoplist.stop?(record)
          return if class_or_module?(record)
          return if fixed_items_model?(record)

          record.freeze

          # Wrap the recursive traversal so a SystemStackError in any descendant
          # does not abort the top-level freeze. The current record is already
          # frozen by the time we get here.
          begin
            deep_freeze_descendants(record)
          rescue SystemStackError => e
            warn_about_bad_reflection(record.class, :"<recursion>", e)
          end
        end

        private

        # A `let_it_be` block that returns a `Class` or `Module` (e.g.
        # `let_it_be(:noteable_type) { Issue }`) is not a per-example
        # fixture -- it is a process-global constant. Freezing it would
        # freeze `Issue` (or any model class) for the lifetime of the test
        # process, so any later spec mutating class-level memoized state
        # (ActiveRecord schema caches, `strong_memoize`, association
        # reflection caches, `reportable_changes_store`, etc.) would crash
        # with `FrozenError` in a completely unrelated example. Constants
        # must never participate in the let_it_be freeze sweep.
        def class_or_module?(record)
          record.is_a?(Module)
        end

        # `ActiveRecord::FixedItemsModel::Model` instances (e.g.
        # `WorkItems::TypesFramework::SystemDefined::Type`,
        # `WorkItems::Statuses::SystemDefined::Status`) are process-global
        # singletons whose data lives in code, not the database.
        # `Type.find(1)` returns the *same* in-memory object across every
        # caller in the process. Freezing one inside a single `let_it_be`
        # would freeze it for the lifetime of the test process, so any later
        # spec calling e.g. `issue.work_item_type.widget_definitions` would
        # crash with `FrozenError` when `strong_memoize` writes its backing
        # ivar -- in a completely unrelated example. These objects are never
        # per-example fixtures, so they should never participate in the
        # let_it_be freeze sweep.
        def fixed_items_model?(record)
          defined?(::ActiveRecord::FixedItemsModel::Model) &&
            record.is_a?(::ActiveRecord::FixedItemsModel::Model)
        end

        def deep_freeze_descendants(record)
          # Check ActiveRecord BEFORE respond_to?(:each) because some AR
          # classes (notably Repository) use `delegate_missing_to`, which
          # makes respond_to?(:each) attempt to delegate to a memoized
          # backing object. Memoization on a frozen record raises
          # FrozenError. ActiveRecord records are not collections; iterate
          # via their reflections instead.
          if defined?(::ActiveRecord::Base) && record.is_a?(::ActiveRecord::Base)
            # `is_a?(ActiveRecord::Base)` forwards through SimpleDelegator-
            # based presenters, but `.class` does not -- so the presenter
            # class may have no `.reflections` method. Skip those entirely.
            return unless record.class.respond_to?(:reflections)

            record.class.reflections.each_key do |reflection|
              walk_reflection(record, reflection)
            end
            return
          end

          return unless record.respond_to?(:each)

          record.each { |rec| deep_freeze(rec) }
        rescue FrozenError => e
          # Defensive: if a model's #respond_to? unexpectedly mutates state
          # (e.g. via delegate_missing_to to a memoized backing object), the
          # record is already frozen at this point and can't be re-frozen.
          # Continue without aborting the freeze sweep.
          warn_about_bad_reflection(record.class, :"<descendants>", e)
        end

        def walk_reflection(record, reflection)
          assoc = record.association(reflection.to_sym)
          return unless assoc.loaded?

          target = assoc.target
          deep_freeze(target) if target.is_a?(::ActiveRecord::Base) || target.respond_to?(:each)
        rescue *RESCUABLE_REFLECTION_ERRORS => e
          warn_about_bad_reflection(record.class, reflection, e)
        end

        def warn_about_bad_reflection(klass, reflection, error)
          key = [klass.name, reflection].freeze
          should_warn = WARNED_REFLECTIONS_MUTEX.synchronize do
            next false if WARNED_REFLECTIONS.include?(key)

            WARNED_REFLECTIONS << key
            true
          end
          return unless should_warn

          warn "[let_it_be deep_freeze] skipping #{klass.name}##{reflection}: " \
            "#{error.class}: #{error.message.lines.first&.strip}. " \
            "Fix the model's association declaration or add freeze: false to the let_it_be call."
        end
      end
    end
  end
end
