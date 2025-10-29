# frozen_string_literal: true

RSpec.shared_examples 'dismissible alert component' do
  let(:user) { build_stubbed(:user) }
  let(:feature_id) { :test_feature }
  let(:component_args) { { title: 'Test Alert', dismiss_options: dismiss_options } }
  let(:dismissed?) { false }

  before do
    allow(callout_model).to receive(:feature_names).and_return([feature_id])
    allow(user).to receive(dismissal_method).and_return(dismissed?)
  end

  subject(:rendered_component) do
    render_inline(described_class.new(**component_args)) do |c|
      c.with_body { 'Alert body content' }
    end
  end

  it 'renders callout alert' do
    expect(rendered_component).to have_css('.gl-alert')
    expect(rendered_component).to have_content('Test Alert')
  end

  it 'adds js-persistent-callout class' do
    expect(rendered_component).to have_css('.js-persistent-callout')
  end

  it 'renders as dismissible alert' do
    expect(rendered_component).to have_css('.js-close.gl-dismiss-btn')
  end

  it 'includes dismiss endpoint and feature_id in data attributes' do
    expect(rendered_component).to have_css("[data-dismiss-endpoint='#{dismiss_endpoint}']")
    expect(rendered_component).to have_css("[data-feature-id='test_feature']")
  end

  if defined?(resource_data_attribute)
    it 'includes resource-specific data attribute' do
      resource_id = dismiss_options[resource_data_attribute[:key]].id
      expect(rendered_component).to have_css("[data-#{resource_data_attribute[:name]}='#{resource_id}']")
    end
  end

  context 'when user has dismissed the callout' do
    let(:dismissed?) { true }

    it 'does not render' do
      expect(rendered_component).not_to have_css('.gl-alert')
    end
  end

  context 'with ignore_dismissal_earlier_than option' do
    let(:ignore_time) { 30.days.ago }
    let(:dismiss_options) { super().merge(ignore_dismissal_earlier_than: ignore_time) }

    it 'passes ignore_dismissal_earlier_than to dismissal method' do
      expect(user).to receive(dismissal_method).with(
        hash_including(ignore_dismissal_earlier_than: ignore_time)
      ).and_return(false)

      rendered_component
    end
  end

  context 'for validation behavior' do
    context 'when feature_id is invalid' do
      let(:dismiss_options) { super().merge(feature_id: :invalid_feature) }

      it 'raises ArgumentError for invalid feature_id' do
        expect do
          rendered_component
        end.to raise_error(ArgumentError, /Feature ID 'invalid_feature' not found in/)
      end
    end

    context 'when user is missing' do
      let(:dismiss_options) { super().merge(user: nil) }

      it 'raises ArgumentError for missing user' do
        expect do
          rendered_component
        end.to raise_error(ArgumentError, 'dismiss_options[:user] is required')
      end
    end
  end

  context 'for wrapper functionality' do
    let(:component_args) { super().merge(wrapper_options: wrapper_options) }
    let(:wrapper_options) { { tag: :section, class: 'settings expanded' } }

    it 'renders the alert wrapped in the specified tag with attributes' do
      expect(rendered_component).to have_css('section.settings.expanded .gl-alert')
      expect(rendered_component).to have_content('Test Alert')
      expect(rendered_component).to have_content('Alert body content')
    end

    it 'renders the alert with has_wrapper data attribute' do
      expect(rendered_component).to have_css('.gl-alert[data-has-wrapper="true"]')
    end

    context 'when wrapper_options specify different tag and attributes' do
      let(:wrapper_options) { { tag: :div, class: 'gl-card gl-p-4', id: 'custom-alert' } }

      it 'renders the alert wrapped in the specified tag with all attributes' do
        expect(rendered_component).to have_css('div.gl-card.gl-p-4#custom-alert .gl-alert')
        expect(rendered_component).to have_content('Test Alert')
        expect(rendered_component).to have_content('Alert body content')
      end
    end

    context 'when wrapper_options only specify attributes without tag' do
      let(:wrapper_options) { { class: 'custom-wrapper', data: { test: 'value' } } }

      it 'defaults to div tag with specified attributes' do
        expect(rendered_component).to have_css('div.custom-wrapper[data-test="value"] .gl-alert')
        expect(rendered_component).to have_content('Test Alert')
        expect(rendered_component).to have_content('Alert body content')
      end
    end
  end
end
