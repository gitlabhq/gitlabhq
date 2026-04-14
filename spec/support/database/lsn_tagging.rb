# frozen_string_literal: true

RSpec.configure do |config|
  # Tag your spec with lsn_tagging: SomeModel to verify LSN tagging behavior on instances of SomeModel with
  # expect(object).to guarantee_lsn(lsn). This will pass if that object was loaded after a stick to the specified lsn.
  # Tag multiple models with `lsn_tagging: [Model1, Model2]`
  config.before(:each, :lsn_tagging) do |example|
    base_models = Array.wrap(example.metadata[:lsn_tagging])

    tagging = Database::LsnTaggingContext.new(base_models)
    models = base_models.flat_map(&:descendants) + base_models
    example.metadata[:lsn_tagging_context] = tagging
    Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
      allow(lb).to receive(:select_up_to_date_host).and_wrap_original do |method, lsn|
        tagging.record_stick!(lb, lsn) # TODO handle use_primary_on_failure: false case
        method.call(lsn)
      end
    end

    models.each do |model|
      next if model.abstract_class?

      # rubocop:disable RSpec/AnyInstanceOf -- Rails instantiates with allocate, allow_next_instance_of does not work
      allow_any_instance_of(model).to receive(:run_callbacks).and_call_original
      allow_any_instance_of(model).to receive(:run_callbacks).with(:find).and_wrap_original do |m, *args, &block|
        ret = m.call(*args, &block)
        model_object = m.receiver
        tagging.record_object_stick(model_object)
        # Hook to reset sticking when object is reloaded too
        allow(model_object).to receive(:reload).and_wrap_original do |reload_m|
          reload_m.call.tap { tagging.record_object_stick(reload_m.receiver) }
        end
        ret
      end
      # rubocop:enable RSpec/AnyInstanceOf
    end
  end
end

RSpec::Matchers.define :guarantee_lsn do |actual_lsn|
  match do |object|
    unless RSpec.current_example.metadata.key?(:lsn_tagging_context)
      raise <<~MSG
        guarantee_lsn matcher requires :lsn_tagging context to record lsn data
      MSG
    end

    guaranteed_lsn = RSpec.current_example.metadata[:lsn_tagging_context].current_lsn_guarantee(object)
    guaranteed_lsn == actual_lsn
  end

  failure_message do |object|
    lsn_guarantee = RSpec.current_example.metadata[:lsn_tagging_context].current_lsn_guarantee(object)

    if lsn_guarantee
      <<~MSG.strip
          expected #{object.inspect} to guarantee lsn #{actual_lsn} but it guaranteed #{lsn_guarantee}
      MSG
    else
      <<~MSG.strip
          expected #{object.inspect} to guarantee lsn #{actual_lsn} but it had no lsn guarantee
      MSG
    end
  end
end

module Database
  class LsnTaggingContext
    def initialize(models)
      @models = models
      # Track by identity because rails models hash based on primary key instead, and this is specifically
      # interested in 2 different instances of the same database row.
      @sticking_guarantees = {}.compare_by_identity
    end

    def record_stick!(load_balancer, lsn)
      (Gitlab::SafeRequestStore[:lsn_tagging_sticking_guarantee] ||= {})[load_balancer] = lsn
    end

    def current_stick_lsn(load_balancer)
      Gitlab::SafeRequestStore[:lsn_tagging_sticking_guarantee]&.[](load_balancer)
    end

    def record_object_stick(model_object)
      @sticking_guarantees[model_object] = current_stick_lsn(model_object.load_balancer)
    end

    def current_lsn_guarantee(model_object)
      unless @models.any? { |m| model_object.is_a?(m) }
        raise ArgumentError, "LSN tagging is not tracking instances of #{model_object.class}"
      end

      @sticking_guarantees[model_object]
    end
  end
end
