# frozen_string_literal: true

RSpec.shared_examples "a layout which reflects the application color mode setting" do
  context 'as a color mode layout' do
    let(:default_color_class) { ::Gitlab::ColorModes.default.css_class }

    context 'when no color mode is explicitly selected' do
      it 'renders with the default color' do
        render

        expect(rendered).to have_selector("html.#{default_color_class}")
      end
    end

    context 'when user is authenticated & has selected a specific color mode' do
      before do
        allow(view).to receive(:user_application_color_mode).and_return(chosen_color_mode.css_class)
      end

      where(chosen_color_mode: ::Gitlab::ColorModes.available_modes)

      with_them do
        it "renders with the #{params[:chosen_color_mode].name} color mode" do
          render

          expect(rendered).to have_selector("html.#{chosen_color_mode.css_class}")
        end
      end
    end
  end
end
