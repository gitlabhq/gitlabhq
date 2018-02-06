require 'spec_helper'

describe U2fHelper do
  describe 'when not on mobile' do
    it 'does not inject u2f on chrome 40' do
      device = double(mobile?: false)
      browser = double(chrome?: true, opera?: false, version: 40, device: device)
      allow(helper).to receive(:browser).and_return(browser)
      expect(helper.inject_u2f_api?).to eq false
    end

    it 'injects u2f on chrome 41' do
      device = double(mobile?: false)
      browser = double(chrome?: true, opera?: false, version: 41, device: device)
      allow(helper).to receive(:browser).and_return(browser)
      expect(helper.inject_u2f_api?).to eq true
    end

    it 'does not inject u2f on opera 39' do
      device = double(mobile?: false)
      browser = double(chrome?: false, opera?: true, version: 39, device: device)
      allow(helper).to receive(:browser).and_return(browser)
      expect(helper.inject_u2f_api?).to eq false
    end

    it 'injects u2f on opera 40' do
      device = double(mobile?: false)
      browser = double(chrome?: false, opera?: true, version: 40, device: device)
      allow(helper).to receive(:browser).and_return(browser)
      expect(helper.inject_u2f_api?).to eq true
    end
  end

  describe 'when on mobile' do
    it 'does not inject u2f on chrome 41' do
      device = double(mobile?: true)
      browser = double(chrome?: true, opera?: false, version: 41, device: device)
      allow(helper).to receive(:browser).and_return(browser)
      expect(helper.inject_u2f_api?).to eq false
    end

    it 'does not inject u2f on opera 40' do
      device = double(mobile?: true)
      browser = double(chrome?: false, opera?: true, version: 40, device: device)
      allow(helper).to receive(:browser).and_return(browser)
      expect(helper.inject_u2f_api?).to eq false
    end
  end
end
