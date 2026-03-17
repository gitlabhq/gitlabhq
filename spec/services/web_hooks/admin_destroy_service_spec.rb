# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::AdminDestroyService, feature_category: :webhooks do
  let(:rake_task) { instance_double(Rake::Task, name: 'gitlab:web_hook:rm', present?: true) }
  let_it_be(:project) { create(:project) }
  let(:web_hook) { create(:project_hook, project: project) }
  let(:service) { described_class.new(rake_task: rake_task) }

  describe '#execute' do
    it 'destroys the web hook' do
      web_hook

      expect { service.execute(web_hook) }.to change { ProjectHook.count }.by(-1)
    end

    it 'returns success' do
      result = service.execute(web_hook)

      expect(result[:status]).to eq(:success)
    end
  end
end
