# frozen_string_literal: true

RSpec.shared_examples 'a finder with external authorization service' do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(user)
  end

  it 'finds the subject' do
    expect(described_class.new(user).execute).to include(subject)
  end

  context 'with an external authorization service' do
    before do
      enable_external_authorization_service_check
    end

    it 'does not include the subject when no project was given' do
      expect(described_class.new(user).execute).not_to include(subject)
    end

    it 'includes the subject when a project id was given' do
      expect(described_class.new(user, project_params).execute).to include(subject)
    end
  end
end
