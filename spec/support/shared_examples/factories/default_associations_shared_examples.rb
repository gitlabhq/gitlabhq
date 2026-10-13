# frozen_string_literal: true

module FactoryDefaults
  # `passed` maps an attribute given to the factory to the factory that creates that record.
  # `skip` lists the factories that must not run when the record is given.
  # `expected` receives (given, strategy) and returns the attributes the built record must have.
  Row = Data.define(:factory, :skip, :passed, :expected, :setup, :strategies, :default_strategy) do
    def initialize(
      factory:, skip:, passed: {}, expected: nil, setup: -> { {} },
      strategies: %i[create build build_stubbed], default_strategy: strategies.last
    )
      super(
        factory: factory, skip: Array(skip), passed: passed, expected: expected, setup: setup,
        strategies: strategies, default_strategy: default_strategy
      )
    end
  end
end

RSpec.shared_examples 'a factory that reuses the passed record' do |row, attribute, kind|
  let_it_be_with_reload(:given) { create(kind) } # rubocop:disable Rails/SaveBang -- FactoryBot, not ActiveRecord

  row.strategies.each do |strategy|
    it "reuses the passed #{attribute} with #{strategy}" do
      setup = instance_exec(&row.setup)
      record = nil

      factories = factory_names_run { record = public_send(strategy, row.factory, attribute => given, **setup) }

      expected = row.expected ? instance_exec(given, strategy, &row.expected) : { attribute => given }

      expect(factories).not_to include(*row.skip)
      expect(record).to have_attributes(expected)
    end
  end
end

RSpec.shared_examples 'a factory that builds its default when nothing is passed' do |row|
  # Fails when a skipped factory never runs, which would make the checks above pass for nothing.
  it "builds #{row.skip.to_sentence} by default" do
    setup = instance_exec(&row.setup)

    factories = factory_names_run { public_send(row.default_strategy, row.factory, **setup) }

    expect(factories).to include(*row.skip)
  end
end

RSpec.shared_examples 'factory default associations' do |rows|
  def factory_names_run(&block)
    names = []
    subscriber = proc { |*args| names << args.last[:factory].name }
    ActiveSupport::Notifications.subscribed(subscriber, 'factory_bot.run_factory', &block)
    names
  end

  rows.each do |row|
    describe ":#{row.factory}" do
      row.passed.each do |attribute, kind|
        context "when #{attribute} is passed" do
          it_behaves_like 'a factory that reuses the passed record', row, attribute, kind
        end
      end

      context 'when nothing is passed' do
        it_behaves_like 'a factory that builds its default when nothing is passed', row
      end
    end
  end
end
