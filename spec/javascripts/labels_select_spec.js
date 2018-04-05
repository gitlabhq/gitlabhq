import $ from 'jquery';
import LabelsSelect from '~/labels_select';

const mockUrl = '/foo/bar/url';

const mockLabels = [
  {
    id: 26,
    title: 'Foo Label',
    description: 'Foobar',
    color: '#BADA55',
    text_color: '#FFFFFF',
  },
];

describe('LabelsSelect', () => {
  describe('getLabelTemplate', () => {
    const label = mockLabels[0];
    let $labelEl;

    beforeEach(() => {
      $labelEl = $(LabelsSelect.getLabelTemplate({
        labels: mockLabels,
        issueUpdateURL: mockUrl,
      }));
    });

    it('generated label item template has correct label URL', () => {
      expect($labelEl.attr('href')).toBe('/foo/bar?label_name[]=Foo%20Label');
    });

    it('generated label item template has correct label title', () => {
      expect($labelEl.find('span.label').text()).toBe(label.title);
    });

    it('generated label item template has label description as title attribute', () => {
      expect($labelEl.find('span.label').attr('title')).toBe(label.description);
    });

    it('generated label item template has correct label styles', () => {
      expect($labelEl.find('span.label').attr('style')).toBe(`background-color: ${label.color}; color: ${label.text_color};`);
    });
  });
});
