# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_error_messages', feature_category: :system_access do
  describe 'Error messages' do
    let(:resource) do
      instance_spy(User, errors: errors, class: User)
    end

    before do
      allow(view).to receive(:resource).and_return(resource)
    end

    context 'with errors', :aggregate_failures do
      let(:errors) { errors_stub(['Invalid name', 'Invalid password']) }

      it 'shows errors' do
        render

        expect(rendered).to have_selector('#error_explanation')
        expect(rendered).to have_content('Invalid name')
        expect(rendered).to have_content('Invalid password')
      end
    end

    context 'without errors' do
      let(:errors) { [] }

      it 'does not show errors' do
        render

        expect(rendered).not_to have_selector('#error_explanation')
      end
    end
  end

  def errors_stub(*messages)
    ActiveModel::Errors.new(double).tap do |errors|
      messages.each { |msg| errors.add(:base, msg) }
    end
  end
end
