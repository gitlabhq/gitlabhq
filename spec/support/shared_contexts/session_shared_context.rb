# frozen_string_literal: true

# the session is empty by default; you can overwrite it by defining your own
# let(:session) variable
# we do not use a parameter such as |session| because it does not play nice
# with let variables
RSpec.shared_context 'custom session' do
  let!(:session) { {} }

  around do |example|
    Gitlab::Session.with_session(session) do
      example.run
    end
  end
end
