# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/organization', feature_category: :cell do
  let_it_be(:organization) { build_stubbed(:organization) }
  let_it_be(:current_user) { build_stubbed(:user, :admin) }

  before do
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(current_user))
    allow(view).to receive(:users_path).and_return('/root')
  end

  subject do
    render

    rendered
  end

  describe 'navigation' do
    context 'when action is #index' do
      before do
        allow(view).to receive(:params).and_return({ action: 'index' })
      end

      it 'renders your_work navigation' do
        subject

        expect(view.instance_variable_get(:@nav)).to eq('your_work')
      end
    end

    context 'when action is #new' do
      before do
        allow(view).to receive(:params).and_return({ action: 'new' })
      end

      it 'renders your_work navigation' do
        subject

        expect(view.instance_variable_get(:@nav)).to eq('your_work')
      end
    end

    context 'when action is #show' do
      before do
        allow(view).to receive(:params).and_return({ action: 'show' })
        view.instance_variable_set(:@organization, organization)
      end

      it 'renders organization navigation' do
        subject

        expect(view.instance_variable_get(:@nav)).to eq('organization')
      end
    end
  end
end
