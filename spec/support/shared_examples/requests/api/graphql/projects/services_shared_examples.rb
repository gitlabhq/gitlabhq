# frozen_string_literal: true

RSpec.shared_examples 'unauthorized users cannot read services' do
  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when anonymous user' do
    let(:current_user) { nil }

    it { expect(services).to be nil }
  end

  context 'when user developer' do
    before do
      project.add_developer(current_user)
    end

    it { expect(services).to be nil }
  end
end
