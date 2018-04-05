require 'spec_helper'

describe 'projects/settings/ci_cd/_form' do
  let(:project) { create(:project, :repository) }

  before do
    assign :project, project
  end

  context 'when kubernetes is not active' do
    context 'when auto devops domain is not defined' do
      it 'shows warning message' do
        render

        expect(rendered).to have_css('.settings-message')
        expect(rendered).to have_text('Auto Review Apps and Auto Deploy need a domain name and a')
        expect(rendered).to have_link('Kubernetes cluster')
      end
    end

    context 'when auto devops domain is defined' do
      before do
        project.build_auto_devops(domain: 'example.com')
      end

      it 'shows warning message' do
        render

        expect(rendered).to have_css('.settings-message')
        expect(rendered).to have_text('Auto Review Apps and Auto Deploy need a')
        expect(rendered).to have_link('Kubernetes cluster')
      end
    end
  end

  context 'when kubernetes is active' do
    before do
      create(:kubernetes_service, project: project)
    end

    context 'when auto devops domain is not defined' do
      it 'shows warning message' do
        render

        expect(rendered).to have_css('.settings-message')
        expect(rendered).to have_text('Auto Review Apps and Auto Deploy need a domain name to work correctly.')
      end
    end

    context 'when auto devops domain is defined' do
      before do
        project.build_auto_devops(domain: 'example.com')
      end

      it 'does not show warning message' do
        render

        expect(rendered).not_to have_css('.settings-message')
      end
    end
  end
end
