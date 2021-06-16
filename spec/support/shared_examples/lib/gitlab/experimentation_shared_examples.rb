# frozen_string_literal: true

RSpec.shared_examples 'tracks assignment and records the subject' do |experiment, subject_type|
  it 'tracks the assignment', :experiment do
    expect(experiment(experiment))
      .to track(:assignment)
      .with_context(subject_type => subject)
      .on_next_instance

    action
  end

  it 'records the subject' do
    stub_experiments(experiment => :candidate)

    expect(Experiment).to receive(:add_subject).with(experiment.to_s, variant: :experimental, subject: subject)

    action
  end
end
