# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RunnerEntity do
  let(:project) { create(:project) }
  let(:runner) { create(:ci_runner, :project, projects: [project]) }
  let(:entity) { described_class.new(runner, request: request, current_user: user) }
  let(:request) { double('request') }
  let(:user) { project.first_owner }

  before do
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:id, :description)
      expect(subject).to include(:edit_path)
      expect(subject).to include(:short_sha)
    end

    context 'without admin permissions' do
      it 'does not contain admin_path field' do
        expect(subject).not_to include(:admin_path)
      end
    end

    context 'with admin permissions' do
      let_it_be(:user) { create(:user, :admin) }

      before do
        allow(user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it 'contains admin_path field' do
        expect(subject).to include(:admin_path)
      end
    end
  end
end
