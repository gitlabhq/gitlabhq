export const mockLabels = [
  {
    id: 26,
    title: 'Foo Label',
    description: 'Foobar',
    color: '#BADA55',
    text_color: '#FFFFFF',
  },
];

export const mockSuggestedColors = [
  '#0033CC',
  '#428BCA',
  '#44AD8E',
  '#A8D695',
  '#5CB85C',
  '#69D100',
  '#004E00',
  '#34495E',
  '#7F8C8D',
  '#A295D6',
  '#5843AD',
  '#8E44AD',
  '#FFECDB',
  '#AD4363',
  '#D10069',
  '#CC0033',
  '#FF0000',
  '#D9534F',
  '#D1D100',
  '#F0AD4E',
  '#AD8D43',
];

export const mockConfig = {
  showCreate: true,
  isProject: true,
  abilityName: 'issue',
  context: {
    labels: mockLabels,
  },
  namespace: 'gitlab-org',
  updatePath: '/gitlab-org/my-project/issue/1',
  labelsPath: '/gitlab-org/my-project/labels.json',
  labelsWebUrl: '/gitlab-org/my-project/labels',
  labelFilterBasePath: '/gitlab-org/my-project/issues',
  canEdit: true,
  suggestedColors: mockSuggestedColors,
  emptyValueText: 'None',
};
