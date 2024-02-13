# frozen_string_literal: true

RSpec.shared_examples 'setting the user_access_level claim' do
  %i[guest reporter developer maintainer owner].each do |access_level|
    context "with a user as a #{access_level}" do
      before do
        project.send("add_#{access_level}", user)
      end

      it 'has the correct value for the user_access_level claim' do
        expect(payload[:user_access_level]).to eq(access_level.to_s)
      end
    end
  end
end
