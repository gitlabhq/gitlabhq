# frozen_string_literal: true

RSpec.shared_examples 'issuable list with anonymous search disabled' do |action|
  let(:controller_action) { :index }
  let(:params_with_search) { params.merge(search: 'some search term') }

  context 'when disable_anonymous_search is enabled' do
    before do
      stub_feature_flags(disable_anonymous_search: true)
    end

    it 'shows a flash message' do
      get controller_action, params: params_with_search

      expect(flash.now[:notice]).to eq('You must sign in to search for specific terms.')
    end

    context 'when search param is not given' do
      it 'does not show a flash message' do
        get controller_action, params: params

        expect(flash.now[:notice]).to be_nil
      end
    end

    context 'when user is signed-in' do
      it 'does not show a flash message' do
        sign_in(create(:user))
        get controller_action, params: params_with_search

        expect(flash.now[:notice]).to be_nil
      end
    end

    context 'when format is not HTML' do
      it 'does not show a flash message' do
        get controller_action, params: params_with_search.merge(format: :atom)

        expect(flash.now[:notice]).to be_nil
      end
    end
  end

  context 'when disable_anonymous_search is disabled' do
    before do
      stub_feature_flags(disable_anonymous_search: false)
    end

    it 'does not show a flash message' do
      get controller_action, params: params_with_search

      expect(flash.now[:notice]).to be_nil
    end
  end
end
