# frozen_string_literal: true

Integration.available_integration_names.each do |integration|
  RSpec.shared_context integration do
    include JiraServiceHelper if integration == 'jira'

    let(:dashed_integration) { integration.dasherize }
    let(:integration_method) { Project.integration_association_name(integration) }
    let(:integration_klass) { Integration.integration_name_to_model(integration) }
    let(:integration_instance) { integration_klass.new }
    let(:integration_fields) { integration_instance.fields }
    let(:integration_attrs_list) { integration_fields.inject([]) {|arr, hash| arr << hash[:name].to_sym } }
    let(:integration_attrs) do
      integration_attrs_list.inject({}) do |hash, k|
        if k =~ /^(token*|.*_token|.*_key)/
          hash.merge!(k => 'secrettoken')
        elsif integration == 'confluence' && k == :confluence_url
          hash.merge!(k => 'https://example.atlassian.net/wiki')
        elsif integration == 'datadog' && k == :datadog_site
          hash.merge!(k => 'datadoghq.com')
        elsif integration == 'packagist' && k == :server
          hash.merge!(k => 'https://packagist.example.com')
        elsif k =~ /^(.*_url|url|webhook)/
          hash.merge!(k => "http://example.com")
        elsif integration_klass.method_defined?("#{k}?")
          hash.merge!(k => true)
        elsif integration == 'irker' && k == :recipients
          hash.merge!(k => 'irc://irc.network.net:666/#channel')
        elsif integration == 'irker' && k == :server_port
          hash.merge!(k => 1234)
        elsif integration == 'jira' && k == :jira_issue_transition_id
          hash.merge!(k => '1,2,3')
        elsif integration == 'emails_on_push' && k == :recipients
          hash.merge!(k => 'foo@bar.com')
        elsif integration == 'slack' || integration == 'mattermost' && k == :labels_to_be_notified_behavior
          hash.merge!(k => "match_any")
        else
          hash.merge!(k => "someword")
        end
      end
    end

    let(:licensed_features) do
      {
        'github' => :github_project_service_integration
      }
    end

    before do
      enable_license_for_integration(integration)
      stub_jira_integration_test if integration == 'jira'
    end

    def initialize_integration(integration, attrs = {})
      record = project.find_or_initialize_integration(integration)
      record.attributes = attrs
      record.properties = integration_attrs
      record.save!
      record
    end

    private

    def enable_license_for_integration(integration)
      return unless respond_to?(:stub_licensed_features)

      licensed_feature = licensed_features[integration]
      return unless licensed_feature

      stub_licensed_features(licensed_feature => true)
      project.clear_memoization(:disabled_integrations)
    end
  end
end

RSpec.shared_context 'integration activation' do
  def click_active_checkbox
    find('label', text: 'Active').click
  end
end
