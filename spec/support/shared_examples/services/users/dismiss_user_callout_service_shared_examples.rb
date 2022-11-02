# frozen_string_literal: true

RSpec.shared_examples_for 'dismissing user callout' do |model|
  it 'creates a new user callout' do
    expect { execute }.to change { model.count }.by(1)
  end

  it 'returns a user callout' do
    expect(execute).to be_an_instance_of(model)
  end

  it 'sets the dismissed_at attribute to current time' do
    freeze_time do
      expect(execute).to have_attributes(dismissed_at: Time.current)
    end
  end

  it 'updates an existing callout dismissed_at time' do
    freeze_time do
      old_time = 1.day.ago
      new_time = Time.current
      attributes = params.merge(dismissed_at: old_time, user: user)
      existing_callout = create(model.name.split('::').last.underscore.to_s.to_sym, attributes)

      expect { execute }.to change { existing_callout.reload.dismissed_at }.from(old_time).to(new_time)
    end
  end

  it 'does not update an invalid record with dismissed_at time', :aggregate_failures do
    callout = described_class.new(
      container: nil, current_user: user, params: { feature_name: nil }
    ).execute

    expect(callout.dismissed_at).to be_nil
    expect(callout).to be_invalid
  end
end
