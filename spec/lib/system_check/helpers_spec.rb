# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Helpers, feature_category: :tooling do
  let(:helper_class) do
    Class.new do
      include SystemCheck::Helpers
    end
  end

  subject(:helper) { helper_class.new }

  describe '#for_more_information' do
    it 'converts doc/ paths to full help page URLs' do
      expected_url = Rails.application.routes.url_helpers.help_page_url('install/self_compiled/_index.md')

      expect { helper.for_more_information('doc/install/self_compiled/_index.md') }
        .to output(/#{Regexp.escape(expected_url)}/).to_stdout
    end

    it 'converts doc/ paths with anchors to full help page URLs' do
      expected_url = Rails.application.routes.url_helpers.help_page_url(
        'install/self_compiled/_index.md', anchor: 'install-init-script'
      )

      expect { helper.for_more_information('doc/install/self_compiled/_index.md#install-init-script') }
        .to output(/#{Regexp.escape(expected_url)}/).to_stdout
    end

    it 'passes through full URLs unchanged' do
      url = 'https://about.gitlab.com/solutions/geo/'

      expect { helper.for_more_information(url) }
        .to output(/#{Regexp.escape(url)}/).to_stdout
    end

    it 'passes through plain text unchanged' do
      text = 'see log/sidekiq.log for possible errors'

      expect { helper.for_more_information(text) }
        .to output(/#{Regexp.escape(text)}/).to_stdout
    end

    it 'passes through doc paths with prose text unchanged' do
      text = "doc/development/database/multiple_databases.md in section 'Truncating tables'"

      expect { helper.for_more_information(text) }
        .to output(/#{Regexp.escape(text)}/).to_stdout
    end
  end

  describe '#see_installation_guide_section' do
    it 'returns a doc path with an anchor' do
      result = helper.see_installation_guide_section('Install Init Script')

      expect(result).to eq('doc/install/self_compiled/_index.md#install-init-script')
    end
  end
end
