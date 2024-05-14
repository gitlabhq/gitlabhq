# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FormBuilders::GitlabUiFormBuilder do
  include FormBuilderHelpers

  let_it_be(:user) { build(:user, :admin) }

  let_it_be(:form_builder) { described_class.new(:user, user, fake_action_view_base, {}) }

  describe '#submit' do
    context 'without pajamas_button enabled' do
      subject(:submit_html) do
        form_builder.submit('Save', class: 'gl-button btn-confirm custom-class', data: { test: true })
      end

      it 'renders a submit input' do
        expected_html = <<~EOS
        <input type="submit" name="commit" value="Save" class="gl-button btn-confirm custom-class" data-test="true" data-disable-with="Save" />
        EOS

        expect(html_strip_whitespace(submit_html)).to eq(html_strip_whitespace(expected_html))
      end
    end

    context 'with pajamas_button enabled' do
      subject(:submit_html) do
        form_builder.submit('Save', pajamas_button: true, class: 'custom-class', data: { test: true })
      end

      it 'renders a submit button' do
        expected_html = <<~EOS
        <button class="gl-button btn btn-md btn-confirm custom-class" data-test="true" type="submit">
          <span class="gl-button-text">
            Save
          </span>
        </button>
        EOS

        expect(html_strip_whitespace(submit_html)).to eq(html_strip_whitespace(expected_html))
      end
    end
  end

  describe '#gitlab_ui_checkbox_component' do
    context 'when not using slots' do
      let(:optional_args) { {} }

      subject(:checkbox_html) do
        form_builder.gitlab_ui_checkbox_component(
          :view_diffs_file_by_file,
          "Show one file at a time on merge request's Changes tab",
          **optional_args
        )
      end

      context 'without optional arguments' do
        it 'renders correct html' do
          expected_html = <<~EOS
            <div class="gl-form-checkbox custom-control custom-checkbox">
              <input name="user[view_diffs_file_by_file]" type="hidden" value="0" autocomplete="off" />
              <input class="custom-control-input" type="checkbox" value="1" name="user[view_diffs_file_by_file]" id="user_view_diffs_file_by_file" />
              <label class="custom-control-label" for="user_view_diffs_file_by_file">
                <span>Show one file at a time on merge request&#39;s Changes tab</span>
              </label>
            </div>
          EOS

          expect(html_strip_whitespace(checkbox_html)).to eq(html_strip_whitespace(expected_html))
        end
      end

      context 'with optional arguments' do
        let(:optional_args) do
          {
            help_text: 'Instead of all the files changed, show only one file at a time.',
            checkbox_options: { class: 'checkbox-foo-bar' },
            label_options: { class: 'label-foo-bar' },
            content_wrapper_options: { class: 'wrapper-foo-bar' },
            checked_value: '3',
            unchecked_value: '1'
          }
        end

        it 'renders help text' do
          expected_html = <<~EOS
            <div class="gl-form-checkbox custom-control custom-checkbox wrapper-foo-bar">
              <input name="user[view_diffs_file_by_file]" type="hidden" value="1" autocomplete="off" />
              <input class="custom-control-input checkbox-foo-bar" type="checkbox" value="3" name="user[view_diffs_file_by_file]" id="user_view_diffs_file_by_file" />
              <label class="custom-control-label label-foo-bar" for="user_view_diffs_file_by_file">
                <span>Show one file at a time on merge request&#39;s Changes tab</span>
                <p class="help-text" data-testid="pajamas-component-help-text">Instead of all the files changed, show only one file at a time.</p>
              </label>
            </div>
          EOS

          expect(html_strip_whitespace(checkbox_html)).to eq(html_strip_whitespace(expected_html))
        end
      end

      context 'with checkbox_options: { multiple: true }' do
        let(:optional_args) do
          {
            checkbox_options: { multiple: true },
            checked_value: 'one',
            unchecked_value: false
          }
        end

        it 'renders labels with correct for attributes' do
          expected_html = <<~EOS
            <div class="gl-form-checkbox custom-control custom-checkbox">
              <input class="custom-control-input" type="checkbox" value="one" name="user[view_diffs_file_by_file][]" id="user_view_diffs_file_by_file_one" />
              <label class="custom-control-label" for="user_view_diffs_file_by_file_one">
                <span>Show one file at a time on merge request&#39;s Changes tab</span>
              </label>
            </div>
          EOS

          expect(html_strip_whitespace(checkbox_html)).to eq(html_strip_whitespace(expected_html))
        end
      end
    end

    context 'when using slots' do
      subject(:checkbox_html) do
        form_builder.gitlab_ui_checkbox_component(
          :view_diffs_file_by_file
        ) do |c|
          c.with_label { "Show one file at a time on merge request's Changes tab" }
          c.with_help_text { 'Instead of all the files changed, show only one file at a time.' }
        end
      end

      it 'renders correct html' do
        expected_html = <<~EOS
          <div class="gl-form-checkbox custom-control custom-checkbox">
            <input name="user[view_diffs_file_by_file]" type="hidden" value="0" autocomplete="off" />
            <input class="custom-control-input" type="checkbox" value="1" name="user[view_diffs_file_by_file]" id="user_view_diffs_file_by_file" />
            <label class="custom-control-label" for="user_view_diffs_file_by_file">
              <span>Show one file at a time on merge request&#39;s Changes tab</span>
              <p class="help-text" data-testid="pajamas-component-help-text">Instead of all the files changed, show only one file at a time.</p>
            </label>
          </div>
        EOS

        expect(html_strip_whitespace(checkbox_html)).to eq(html_strip_whitespace(expected_html))
      end
    end
  end

  describe '#gitlab_ui_radio_component' do
    context 'when not using slots' do
      let(:optional_args) { {} }

      subject(:radio_html) do
        form_builder.gitlab_ui_radio_component(
          :access_level,
          :admin,
          "Admin",
          **optional_args
        )
      end

      context 'without optional arguments' do
        it 'renders correct html' do
          expected_html = <<~EOS
            <div class="gl-form-radio custom-control custom-radio">
              <input class="custom-control-input" type="radio" value="admin" checked="checked" name="user[access_level]" id="user_access_level_admin" />
              <label class="custom-control-label" for="user_access_level_admin">
                <span>Admin</span>
              </label>
            </div>
          EOS

          expect(html_strip_whitespace(radio_html)).to eq(html_strip_whitespace(expected_html))
        end
      end

      context 'with optional arguments' do
        let(:optional_args) do
          {
            help_text: 'Administrators have access to all groups, projects, and users and can manage all features in this installation',
            radio_options: { class: 'radio-foo-bar' },
            label_options: { class: 'label-foo-bar' }
          }
        end

        it 'renders help text' do
          expected_html = <<~EOS
            <div class="gl-form-radio custom-control custom-radio">
              <input class="custom-control-input radio-foo-bar" type="radio" value="admin" checked="checked" name="user[access_level]" id="user_access_level_admin" />
              <label class="custom-control-label label-foo-bar" for="user_access_level_admin">
                <span>Admin</span>
                <p class="help-text" data-testid="pajamas-component-help-text">Administrators have access to all groups, projects, and users and can manage all features in this installation</p>
              </label>
            </div>
          EOS

          expect(html_strip_whitespace(radio_html)).to eq(html_strip_whitespace(expected_html))
        end
      end
    end

    context 'when using slots' do
      subject(:radio_html) do
        form_builder.gitlab_ui_radio_component(
          :access_level,
          :admin
        ) do |c|
          c.with_label { "Admin" }
          c.with_help_text { 'Administrators have access to all groups, projects, and users and can manage all features in this installation' }
        end
      end

      it 'renders correct html' do
        expected_html = <<~EOS
          <div class="gl-form-radio custom-control custom-radio">
            <input class="custom-control-input" type="radio" value="admin" checked="checked" name="user[access_level]" id="user_access_level_admin" />
            <label class="custom-control-label" for="user_access_level_admin">
              <span>Admin</span>
              <p class="help-text" data-testid="pajamas-component-help-text">Administrators have access to all groups, projects, and users and can manage all features in this installation</p>
            </label>
          </div>
        EOS

        expect(html_strip_whitespace(radio_html)).to eq(html_strip_whitespace(expected_html))
      end
    end
  end

  describe '#gitlab_ui_datepicker' do
    subject(:datepicker_html) do
      form_builder.gitlab_ui_datepicker(
        :expires_at,
        **optional_args
      )
    end

    let(:optional_args) { {} }

    context 'without optional arguments' do
      it 'renders correct html' do
        expected_html = <<~EOS
          <input class="datepicker form-control gl-form-input" type="text" name="user[expires_at]" id="user_expires_at" />
        EOS

        expect(html_strip_whitespace(datepicker_html)).to eq(html_strip_whitespace(expected_html))
      end
    end

    context 'with optional arguments' do
      let(:optional_args) do
        {
          id: 'milk_gone_bad',
          data: { action: 'throw' },
          value: '2022-08-01'
        }
      end

      it 'renders correct html' do
        expected_html = <<~EOS
          <input id="milk_gone_bad" data-action="throw" value="2022-08-01" class="datepicker form-control gl-form-input" type="text" name="user[expires_at]" />
        EOS

        expect(html_strip_whitespace(datepicker_html)).to eq(html_strip_whitespace(expected_html))
      end
    end
  end

  private

  def html_strip_whitespace(html)
    html.lines.map(&:strip).join('')
  end
end
