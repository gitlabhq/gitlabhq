# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RunnerEntity do
  let(:owner) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project, namespace: build_stubbed(:namespace, owner: owner)) }
  let(:runner) do
    build_stubbed(:ci_runner, :project, projects: [project]).tap do |stubbed_runner|
      stubbed_runner.set_token('abcdefghij1234567890')
    end
  end

  let(:entity) { described_class.new(runner, request: request, current_user: user) }
  let(:request) { double('request') }
  let(:user) { project.first_owner }

  before do
    allow(request).to receive_messages(current_user: user, project: project)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:id, :description)
      expect(subject).to include(:edit_path)
      expect(subject).to include(:short_sha)
    end

    it 'contains edit_path field' do
      expect(subject).to include(:edit_path)
    end

    context 'without admin permissions' do
      it 'does not contain admin_path field' do
        expect(subject).not_to include(:admin_path)
      end
    end

    context 'with admin permissions', :enable_admin_mode do
      let(:user) { build_stubbed(:user, :admin) }

      it 'contains admin_path field' do
        expect(subject).to include(:admin_path)
      end
    end
  end
end
