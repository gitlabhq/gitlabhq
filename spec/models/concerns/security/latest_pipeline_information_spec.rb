# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::LatestPipelineInformation, feature_category: :artifact_security do
  subject { my_class.latest_builds_reports }

  let(:my_class) do
    Class.new do
      include Security::LatestPipelineInformation
      include Gitlab::Utils::StrongMemoize
    end
  end

  let(:instance) { my_class.new }

  let_it_be(:pipeline) { create(:ci_pipeline) }

  describe '#scanner_enabled?' do
    it 'returns true if the scan type is included in latest_builds_reports' do
      allow(instance).to receive(:latest_builds_reports).and_return([:sast, :dast])
      expect(instance.send(:scanner_enabled?, :sast)).to be true
    end

    it 'returns false if the scan type is not included in latest_builds_reports' do
      allow(instance).to receive(:latest_builds_reports).and_return([:dast])
      expect(instance.send(:scanner_enabled?, :sast)).to be false
    end
  end

  describe '#latest_builds_reports' do
    let_it_be(:sast_build) { create(:ci_build, :sast, :success, name: "semgrep-sast", pipeline: pipeline) }
    let_it_be(:sast_iac_build) { create(:ci_build, :sast, name: "kics-iac-sast", pipeline: pipeline) }
    let_it_be(:advanced_sast_build) { create(:ci_build, :sast, name: "gitlab-advanced-sast", pipeline: pipeline) }
    let_it_be(:dast_build) { create(:ci_build, :dast, pipeline: pipeline) }

    it 'returns an array of unique reports' do
      allow(instance).to receive(:latest_security_builds).and_return([sast_build, advanced_sast_build, dast_build])
      expect(instance.send(:latest_builds_reports)).to match_array([:sast, :sast_advanced, :dast])
    end

    context 'when limiting to successful builds' do
      it 'returns an array of reports with only successful builds' do
        allow(instance).to receive(:latest_security_builds).and_return([sast_build, sast_iac_build])
        expect(instance.send(:latest_builds_reports, only_successful_builds: true)).to match_array([:sast])
      end
    end

    describe 'sast jobs' do
      it 'does not include :sast when there are no sast related jobs' do
        allow(instance).to receive(:latest_security_builds).and_return([dast_build])
        expect(instance.send(:latest_builds_reports)).to match_array([:dast])
      end

      it 'includes :sast when the only job is :sast_advanced' do
        allow(instance).to receive(:latest_security_builds).and_return([advanced_sast_build])
        expect(instance.send(:latest_builds_reports)).to match_array([:sast, :sast_advanced])
      end

      it 'does not include :sast when the only job is :sast_iac' do
        allow(instance).to receive(:latest_security_builds).and_return([sast_iac_build])
        expect(instance.send(:latest_builds_reports)).to match_array([:sast_iac])
      end

      it 'does not include :sast_iac or :sast_advanced when there are only :sast jobs' do
        allow(instance).to receive(:latest_security_builds).and_return([sast_build])
        expect(instance.send(:latest_builds_reports)).to match_array([:sast])
      end
    end
  end
end
