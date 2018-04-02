import { getTimeframeWindow } from '~/lib/utils/datetime_utility';
import { TIMEFRAME_LENGTH } from 'ee/roadmap/constants';

export const mockScrollBarSize = 15;

export const mockGroupId = 2;

export const mockShellWidth = 2000;

export const mockItemWidth = 180;

export const epicsPath = '/groups/gitlab-org/-/epics.json?start_date=2017-11-1&end_date=2018-4-30';

export const mockSvgPath = '/foo/bar.svg';

export const mockTimeframe = getTimeframeWindow(TIMEFRAME_LENGTH, new Date(2018, 1, 1));

export const mockEpic = {
  id: 1,
  iid: 1,
  description: 'Explicabo et soluta minus praesentium minima ab et voluptatem. Quas architecto vero corrupti voluptatibus labore accusantium consectetur. Aliquam aut impedit voluptates illum molestias aut harum. Aut non odio praesentium aut.\n\nQuo asperiores aliquid sed nobis. Omnis sint iste provident numquam. Qui voluptatem tempore aut aut voluptas dolorem qui.\n\nEst est nemo quod est. Odit modi eos natus cum illo aut. Expedita nostrum ea est omnis magnam ut eveniet maxime. Itaque ipsam provident minima et occaecati ut. Dicta est perferendis sequi perspiciatis rerum voluptatum deserunt.',
  title: 'Cupiditate exercitationem unde harum reprehenderit maxime eius velit recusandae incidunt quia.',
  groupId: 2,
  groupName: 'Gitlab Org',
  groupFullName: 'Gitlab Org',
  startDate: new Date('2017-07-10'),
  endDate: new Date('2018-06-02'),
  webUrl: '/groups/gitlab-org/-/epics/1',
};

export const rawEpics = [
  {
    id: 41,
    iid: 2,
    description: null,
    title: 'Another marketing',
    group_id: 56,
    group_name: 'Marketing',
    group_full_name: 'Gitlab Org / Marketing',
    start_date: '2017-12-26',
    end_date: '2018-03-10',
    web_url: '/groups/gitlab-org/marketing/-/epics/2',
  },
  {
    id: 40,
    iid: 1,
    description: null,
    title: 'Marketing epic',
    group_id: 56,
    group_name: 'Marketing',
    group_full_name: 'Gitlab Org / Marketing',
    start_date: '2017-12-25',
    end_date: '2018-03-09',
    web_url: '/groups/gitlab-org/marketing/-/epics/1',
  },
  {
    id: 39,
    iid: 12,
    description: null,
    title: 'Epic with end in first timeframe month',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2017-04-02',
    end_date: '2017-11-30',
    web_url: '/groups/gitlab-org/-/epics/12',
  },
  {
    id: 38,
    iid: 11,
    description: null,
    title: 'Epic with end date out of range',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2018-01-15',
    end_date: '2020-01-03',
    web_url: '/groups/gitlab-org/-/epics/11',
  },
  {
    id: 37,
    iid: 10,
    description: null,
    title: 'Epic with timeline in same month',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2018-01-01',
    end_date: '2018-01-31',
    web_url: '/groups/gitlab-org/-/epics/10',
  },
  {
    id: 35,
    iid: 8,
    description: null,
    title: 'Epic with out of range start & null end',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2017-09-04',
    end_date: null,
    web_url: '/groups/gitlab-org/-/epics/8',
  },
  {
    id: 33,
    iid: 6,
    description: null,
    title: 'Epic with only start date',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2017-11-27',
    end_date: null,
    web_url: '/groups/gitlab-org/-/epics/6',
  },
  {
    id: 4,
    iid: 4,
    description: 'Animi dolorem error ipsam assumenda. Dolor reprehenderit sit soluta molestias id. Explicabo vel dolores numquam earum ut aliquid. Quisquam aliquam a totam laborum quia.\n\nEt voluptatem reiciendis qui cum. Labore ratione delectus minus et voluptates. Dolor voluptatem nisi neque fugiat ut ullam dicta odit. Aut quaerat provident ducimus aut molestiae hic esse.\n\nSuscipit non repellat laudantium quaerat. Voluptatum dolor explicabo vel illo earum. Laborum vero occaecati qui autem cumque dolorem autem. Enim voluptatibus a dolorem et.',
    title: 'Et repellendus quo et laboriosam corrupti ex nisi qui.',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2018-01-01',
    end_date: '2018-02-02',
    web_url: '/groups/gitlab-org/-/epics/4',
  },
  {
    id: 3,
    iid: 3,
    description: 'Magnam placeat ut esse aut vel. Et sit ab soluta ut eos et et. Nesciunt expedita sit et optio maiores quas facilis. Provident ut aut et nihil. Nesciunt ipsum fuga labore dolor quia.\n\nSit suscipit impedit aut dolore non provident. Nesciunt nemo excepturi voluptatem natus veritatis. Vel ut possimus reiciendis dolorem et. Recusandae voluptatem voluptatum aut iure. Sapiente quia est iste similique quidem quia omnis et.\n\nId aut assumenda beatae iusto est dicta consequatur. Tempora voluptatem pariatur ab velit vero ut reprehenderit fuga. Dolor modi aspernatur eos atque eveniet harum sed voluptatem. Dolore iusto voluptas dolor enim labore dolorum consequatur dolores.',
    title: 'Nostrum ut nisi fugiat accusantium qui velit dignissimos.',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2017-12-01',
    end_date: '2018-03-26',
    web_url: '/groups/gitlab-org/-/epics/3',
  },
  {
    id: 2,
    iid: 2,
    description: 'Deleniti id facere numquam cum consectetur sint ipsum consequatur. Odit nihil harum consequuntur est nemo adipisci. Incidunt suscipit voluptatem et culpa at voluptatem consequuntur. Rerum aliquam earum quia consequatur ipsam quae ut.\n\nQuod molestias ducimus quia ratione nostrum ut adipisci. Fugiat officiis reiciendis repellendus quia ut ipsa. Voluptatum ut dolor perferendis nostrum. Porro a ducimus sequi qui quos ea. Earum velit architecto necessitatibus at dicta.\n\nModi aut non fugiat autem doloribus nobis ea. Sit quam corrupti blanditiis nihil tempora ratione enim ex. Aliquam quia ut impedit ut velit reprehenderit quae amet. Unde quod at dolorum eligendi in ducimus perspiciatis accusamus.',
    title: 'Sit beatae amet quaerat consequatur non repudiandae qui.',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2017-11-26',
    end_date: '2018-03-22',
    web_url: '/groups/gitlab-org/-/epics/2',
  },
  {
    id: 1,
    iid: 1,
    description: 'Explicabo et soluta minus praesentium minima ab et voluptatem. Quas architecto vero corrupti voluptatibus labore accusantium consectetur. Aliquam aut impedit voluptates illum molestias aut harum. Aut non odio praesentium aut.\n\nQuo asperiores aliquid sed nobis. Omnis sint iste provident numquam. Qui voluptatem tempore aut aut voluptas dolorem qui.\n\nEst est nemo quod est. Odit modi eos natus cum illo aut. Expedita nostrum ea est omnis magnam ut eveniet maxime. Itaque ipsam provident minima et occaecati ut. Dicta est perferendis sequi perspiciatis rerum voluptatum deserunt.',
    title: 'Cupiditate exercitationem unde harum reprehenderit maxime eius velit recusandae incidunt quia.',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2017-07-10',
    end_date: '2018-06-02',
    web_url: '/groups/gitlab-org/-/epics/1',
  },
];

