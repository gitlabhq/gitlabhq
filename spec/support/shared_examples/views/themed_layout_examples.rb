# frozen_string_literal: true

RSpec.shared_examples "a layout which reflects the application theme setting" do
  context 'as a themed layout' do
    let(:default_theme_class) { ::Gitlab::Themes.default.css_class }

    context 'when no theme is explicitly selected' do
      it 'renders with the default theme' do
        render

        expect(rendered).to have_selector("html.#{default_theme_class}")
      end
    end

    context 'when user is authenticated & has selected a specific theme' do
      before do
        allow(view).to receive(:user_application_theme).and_return(chosen_theme.css_class)
      end

      where(chosen_theme: ::Gitlab::Themes.available_themes)

      with_them do
        it "renders with the #{params[:chosen_theme].name} theme" do
          render

          if chosen_theme.css_class != default_theme_class
            expect(rendered).not_to have_selector("html.#{default_theme_class}")
          end

          expect(rendered).to have_selector("html.#{chosen_theme.css_class}")
        end
      end
    end
  end
end
