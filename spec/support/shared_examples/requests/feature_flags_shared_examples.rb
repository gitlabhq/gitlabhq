# frozen_string_literal: true

RSpec.shared_examples 'pushed feature flag' do |feature_flag_name|
  let(:feature_flag_name_camelized) { feature_flag_name.to_s.camelize(:lower).to_sym }

  it "pushes feature flag :#{feature_flag_name} `true` to the view" do
    subject

    expect(response.body).to have_pushed_frontend_feature_flags(feature_flag_name_camelized => true)
  end

  context "when feature flag :#{feature_flag_name} is disabled" do
    before do
      stub_feature_flags(feature_flag_name.to_sym => false)
    end

    it "pushes feature flag :#{feature_flag_name} `false` to the view" do
      subject

      expect(response.body).to have_pushed_frontend_feature_flags(feature_flag_name_camelized => false)
    end
  end
end
