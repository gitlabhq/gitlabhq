# frozen_string_literal: true

require 'spec_helper'

describe GrafanaIntegration do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:token) }

    it 'disallows invalid urls for grafana_url' do
      unsafe_url = %{https://replaceme.com/'><script>alert(document.cookie)</script>}
      non_ascii_url = 'http://gitlab.com/api/0/projects/project1/something€'
      blank_url = ''
      excessively_long_url = 'https://grafan' + 'a' * 1024 + '.com'

      is_expected.not_to allow_values(
        unsafe_url,
        non_ascii_url,
        blank_url,
        excessively_long_url
      ).for(:grafana_url)
    end

    it 'allows valid urls for grafana_url' do
      external_url = 'http://grafana.com/'
      internal_url = 'http://192.168.1.1'

      is_expected.to allow_value(
        external_url,
        internal_url
      ).for(:grafana_url)
    end
  end
end
