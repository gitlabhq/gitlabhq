# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/cookie_setting'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::CookieSetting, feature_category: :tooling do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:comment_text) { "\n#{described_class::SUGGESTION}" }
  let(:file_lines) { file_diff.map { |line| line.delete_prefix('+') } }

  before do
    allow(cookie_setting).to receive(:project_helper).and_return(fake_project_helper)
    allow(cookie_setting.project_helper).to receive(:file_lines).and_return(file_lines)
    allow(cookie_setting.helper).to receive(:added_files).and_return([filename])
    allow(cookie_setting.helper).to receive(:changed_lines).with(filename).and_return(file_diff)

    cookie_setting.define_singleton_method(:add_suggestions_for) do |filename|
      Tooling::Danger::CookieSetting.new(filename, context: self).suggest
    end
  end

  subject(:cookie_setting) { fake_danger.new(helper: fake_helper) }

  context 'for single line method call' do
    let(:file_diff) do
      <<~DIFF.split("\n")
        +    def index
        +      #{code}
        +
        +      render text: 'OK'
        +    end
      DIFF
    end

    context 'when file is a non-spec Ruby file' do
      let(:filename) { 'app/controllers/user_settings/active_sessions_controller.rb' }

      using RSpec::Parameterized::TableSyntax

      context 'when comment is expected' do
        where(:code) do
          [
            'cookies[:my_key] = true',
            'cookies["my_key"] = true',
            'cookies[\'my_key\'] = true',
            'cookies[:my_key] = { value: "nbd", expires: 1.year, domain: "example.com" }',
            'cookies.encrypted[:my_key] = true',
            'cookies.permanent[:my_key] = true',
            'cookies.signed[:my_key] = true',
            'cookies.signed.encrypted.permanent[:my_key] = true',
            'cookies[Example::Class::With::CONSTANT] = true',
            'cookies[Example::Class::With::CONSTANT] = { value: "nbd", expires: 1.year, domain: "example.com" }',
            'cookies.encrypted[Example::Class::With::CONSTANT] = { value: "nbd", domain: "example.com" }',
            'cookies.permanent[Example::Class::With::CONSTANT] = { value: "nbd", domain: "example.com" }',
            'cookies.signed[Example::Class::With::CONSTANT] = { value: "nbd", domain: "example.com" }'
          ]
        end

        with_them do
          specify do
            expect(cookie_setting).to receive(:markdown).with(comment_text.chomp, file: filename, line: 2)

            cookie_setting.add_suggestions_for(filename)
          end
        end
      end

      context 'when no comment is expected' do
        where(:code) do
          [
            'cookies[:my_cookie].blank?',
            'cookies.signed[Some::Class::With::CONSTANTS].blank?',
            'cookies[:my_cookie] == "true"',
            'cookies.encrypted[:my_cookie] += "true"'
          ]
        end

        with_them do
          specify do
            expect(cookie_setting).not_to receive(:markdown)

            cookie_setting.add_suggestions_for(filename)
          end
        end
      end
    end
  end
end
