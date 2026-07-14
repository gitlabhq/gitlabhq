# frozen_string_literal: true

RSpec.shared_examples 'defines control and candidate variants' do
  let(:experiment_name) { described_class.experiment_name(suffix: false).to_sym }
  let(:exp) { experiment(experiment_name) }

  it 'overrides context_keys with symbol keys' do
    expect(described_class.context_keys).to all(be_a(Symbol))
  end

  context 'with candidate experience' do
    before do
      stub_experiments(experiment_name => :candidate)
    end

    it 'does not raise an error' do
      expect(exp).to register_behavior(:candidate).with(nil)
      expect { exp.run }.not_to raise_error
    end
  end

  context 'with control experience' do
    before do
      stub_experiments(experiment_name => :control)
    end

    it 'does not raise an error' do
      expect(exp).to register_behavior(:control).with(nil)
      expect { exp.run }.not_to raise_error
    end
  end
end
