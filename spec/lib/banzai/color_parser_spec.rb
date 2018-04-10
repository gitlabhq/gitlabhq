require 'spec_helper'

describe Banzai::ColorParser do
  describe '.parse' do
    context 'HEX format' do
      [
        '#abc', '#ABC',
        '#d2d2d2', '#D2D2D2',
        '#123a', '#123A',
        '#123456aa', '#123456AA'
      ].each do |color|
        it "parses the valid hex color #{color}" do
          expect(subject.parse(color)).to eq(color)
        end
      end

      [
        '#', '#1', '#12', '#12g', '#12G',
        '#12345', '#r2r2r2', '#R2R2R2', '#1234567',
        '# 123', '# 1234', '# 123456', '# 12345678',
        '#1 2 3', '#123 4', '#12 34 56', '#123456 78'
      ].each do |color|
        it "does not parse the invalid hex color #{color}" do
          expect(subject.parse(color)).to be_nil
        end
      end
    end

    context 'RGB format' do
      [
        'rgb(0,0,0)', 'rgb(255,255,255)',
        'rgb(0, 0, 0)', 'RGB(0,0,0)',
        'rgb(0,0,0,0)',  'rgb(0,0,0,0.0)',  'rgb(0,0,0,.0)',
        'rgb(0,0,0, 0)', 'rgb(0,0,0, 0.0)', 'rgb(0,0,0, .0)',
        'rgb(0,0,0,1)',  'rgb(0,0,0,1.0)',
        'rgba(0,0,0)', 'rgba(0,0,0,0)', 'RGBA(0,0,0)',
        'rgb(0%,0%,0%)', 'rgba(0%,0%,0%,0%)'
      ].each do |color|
        it "parses the valid rgb color #{color}" do
          expect(subject.parse(color)).to eq(color)
        end
      end

      [
        'FOOrgb(0,0,0)', 'rgb(0,0,0)BAR',
        'rgb(0,0,-1)', 'rgb(0,0,-0)', 'rgb(0,0,256)',
        'rgb(0,0,0,-0.1)', 'rgb(0,0,0,-0.0)', 'rgb(0,0,0,-.1)',
        'rgb(0,0,0,1.1)',  'rgb(0,0,0,2)',
        'rgba(0,0,0,)', 'rgba(0,0,0,0.)', 'rgba(0,0,0,1.)',
        'rgb(0,0,0%)', 'rgb(101%,0%,0%)'
      ].each do |color|
        it "does not parse the invalid rgb color #{color}" do
          expect(subject.parse(color)).to be_nil
        end
      end
    end

    context 'HSL format' do
      [
        'hsl(0,0%,0%)',  'hsl(0,100%,100%)',
        'hsl(540,0%,0%)', 'hsl(-720,0%,0%)',
        'hsl(0deg,0%,0%)', 'hsl(0DEG,0%,0%)',
        'hsl(0, 0%, 0%)', 'HSL(0,0%,0%)',
        'hsl(0,0%,0%,0)', 'hsl(0,0%,0%,0.0)', 'hsl(0,0%,0%,.0)',
        'hsl(0,0%,0%, 0)', 'hsl(0,0%,0%, 0.0)', 'hsl(0,0%,0%, .0)',
        'hsl(0,0%,0%,1)', 'hsl(0,0%,0%,1.0)',
        'hsla(0,0%,0%)', 'hsla(0,0%,0%,0)', 'HSLA(0,0%,0%)',
        'hsl(1rad,0%,0%)', 'hsl(1.1rad,0%,0%)', 'hsl(.1rad,0%,0%)',
        'hsl(-1rad,0%,0%)', 'hsl(1RAD,0%,0%)'
      ].each do |color|
        it "parses the valid hsl color #{color}" do
          expect(subject.parse(color)).to eq(color)
        end
      end

      [
        'hsl(+0,0%,0%)', 'hsl(0,0,0%)', 'hsl(0,0%,0)', 'hsl(0 deg,0%,0%)',
        'hsl(0,-0%,0%)', 'hsl(0,101%,0%)', 'hsl(0,-1%,0%)',
        'hsl(0,0%,0%,-0.1)', 'hsl(0,0%,0%,-.1)',
        'hsl(0,0%,0%,1.1)', 'hsl(0,0%,0%,2)',
        'hsl(0,0%,0%,)', 'hsl(0,0%,0%,0.)', 'hsl(0,0%,0%,1.)',
        'hsl(deg,0%,0%)', 'hsl(rad,0%,0%)'
      ].each do |color|
        it "does not parse the invalid hsl color #{color}" do
          expect(subject.parse(color)).to be_nil
        end
      end
    end
  end
end
