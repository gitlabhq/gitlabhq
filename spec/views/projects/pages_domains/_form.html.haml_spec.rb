# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pages_domains/_form', feature_category: :pages do
  let(:project) { build(:project, :repository) }
  let(:domain) { build(:pages_domain, project: project) }
  let(:form) { instance_double(Gitlab::FormBuilders::GitlabUiFormBuilder, text_field: nil, label: nil) }
  let(:domain_presenter) { domain.present }

  before do
    assign(:project, project)
    allow(view).to receive_messages(domain_presenter: domain_presenter, f: form)
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with('certificate', f: form).and_return('')
  end

  describe 'certificate section rendering' do
    where(:external_https, :custom_domain_mode, :renders_certificate) do
      [
        [true,  'https', true],
        [true,  'http',  true],
        [false, 'https', true],
        [false, 'http',  false]
      ]
    end

    with_them do
      it "when external_https=#{params[:external_https]} and custom_domain_mode=#{params[:custom_domain_mode]}" do
        stub_pages_setting(external_https: external_https, custom_domain_mode: custom_domain_mode)

        if renders_certificate
          expect(view).to receive(:render).with('certificate', f: form)
        else
          expect(view).not_to receive(:render).with('certificate', f: form)
        end

        render partial: 'projects/pages_domains/form'

        unless renders_certificate
          expect(rendered).to have_content(
            "Support for custom certificates is disabled. Ask your system's administrator to enable it.")
        end
      end
    end
  end
end
