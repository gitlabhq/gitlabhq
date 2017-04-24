RSpec::Matchers.define :have_an_activity_record do |expected|
  match do |user|
    expect(Gitlab::UserActivities.new.find { |k, _| k == user.id.to_s }).to be_present
  end
end
