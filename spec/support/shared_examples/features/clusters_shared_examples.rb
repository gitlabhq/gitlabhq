# frozen_string_literal: true

RSpec.shared_examples "user disables a cluster" do
  context 'when user disables the cluster' do
    before do
      page.find(:css, '.js-cluster-enable-toggle-area .js-project-feature-toggle').click
      page.within('.js-cluster-details-form') { click_button 'Save changes' }
    end

    it 'user sees the successful message' do
      expect(page).to have_content('Kubernetes cluster was successfully updated.')
    end
  end
end
