# rubocop:disable Metrics/AbcSize

# Note: The ABC size is large here because we have a method generating test cases with
#       multiple nested contexts. This shouldn't count as a violation.

module CycleAnalyticsHelpers
  # Generate the most common set of specs that all cycle analytics phases need to have.
  #
  # Arguments:
  #
  #                  phase: Which phase are we testing? Will call `CycleAnalytics.new.send(phase)` for the final assertion
  #                data_fn: A function that returns a hash, constituting initial data for the test case
  #  start_time_conditions: An array of `conditions`. Each condition is an tuple of `condition_name` and `condition_fn`. `condition_fn` is called with
  #                         `context` (no lexical scope, so need to do `context.create` for factories, for example) and `data` (from the `data_fn`).
  #                         Each `condition_fn` is expected to implement a case which consitutes the start of the given cycle analytics phase.
  #    end_time_conditions: An array of `conditions`. Each condition is an tuple of `condition_name` and `condition_fn`. `condition_fn` is called with
  #                         `context` (no lexical scope, so need to do `context.create` for factories, for example) and `data` (from the `data_fn`).
  #                         Each `condition_fn` is expected to implement a case which consitutes the end of the given cycle analytics phase.

  def generate_cycle_analytics_spec(phase:, data_fn:, start_time_conditions:, end_time_conditions:)
    combinations_of_start_time_conditions = (1..start_time_conditions.size).flat_map { |size| start_time_conditions.combination(size).to_a }
    combinations_of_end_time_conditions = (1..end_time_conditions.size).flat_map { |size| end_time_conditions.combination(size).to_a }

    scenarios = combinations_of_start_time_conditions.product(combinations_of_end_time_conditions)
    scenarios.each do |start_time_conditions, end_time_conditions|
      context "start condition: #{start_time_conditions.map(&:first).to_sentence}" do
        context "end condition: #{end_time_conditions.map(&:first).to_sentence}" do
          it "finds the median of available durations between the two conditions" do
            time_differences = Array.new(5) do |index|
              data = data_fn[self]
              start_time = (index * 10).days.from_now
              end_time = start_time + rand(1..5).days

              start_time_conditions.each do |condition_name, condition_fn|
                Timecop.freeze(start_time) { condition_fn[self, data] }
              end

              end_time_conditions.each do |condition_name, condition_fn|
                Timecop.freeze(end_time) { condition_fn[self, data] }
              end

              end_time - start_time
            end

            median_time_difference = time_differences.sort[2]
            expect(subject.send(phase)).to be_within(5).of(median_time_difference)
          end

          context "when the data belongs to another project" do
            let(:other_project) { create(:project) }

            it "returns nil" do
              # Use a stub to "trick" the data/condition functions
              # into using another project. This saves us from having to
              # define separate data/condition functions for this particular
              # test case.
              allow(self).to receive(:project) { other_project }

              5.times do
                data = data_fn[self]
                start_time = Time.now
                end_time = rand(1..10).days.from_now

                start_time_conditions.each do |condition_name, condition_fn|
                  Timecop.freeze(start_time) { condition_fn[self, data] }
                end

                end_time_conditions.each do |condition_name, condition_fn|
                  Timecop.freeze(end_time) { condition_fn[self, data] }
                end
              end

              # Turn off the stub before checking assertions
              allow(self).to receive(:project).and_call_original

              expect(subject.send(phase)).to be_nil
            end
          end
        end
      end

      context "start condition NOT PRESENT: #{start_time_conditions.map(&:first).to_sentence}" do
        context "end condition: #{end_time_conditions.map(&:first).to_sentence}" do
          it "returns nil" do
            5.times do
              data = data_fn[self]
              end_time = rand(1..10).days.from_now

              end_time_conditions.each_with_index do |(condition_name, condition_fn), index|
                Timecop.freeze(end_time + index.days) { condition_fn[self, data] }
              end
            end

            expect(subject.send(phase)).to be_nil
          end
        end
      end

      context "start condition: #{start_time_conditions.map(&:first).to_sentence}" do
        context "end condition NOT PRESENT: #{end_time_conditions.map(&:first).to_sentence}" do
          it "returns nil" do
            5.times do
              data = data_fn[self]
              start_time = Time.now

              start_time_conditions.each do |condition_name, condition_fn|
                Timecop.freeze(start_time) { condition_fn[self, data] }
              end
            end

            expect(subject.send(phase)).to be_nil
          end
        end
      end
    end

    context "when none of the start / end conditions are matched" do
      it "returns nil" do
        expect(subject.send(phase)).to be_nil
      end
    end
  end
end

RSpec.configure do |config|
  config.extend CycleAnalyticsHelpers
end
