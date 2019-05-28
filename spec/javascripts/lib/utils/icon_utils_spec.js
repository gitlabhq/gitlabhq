import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import * as iconUtils from '~/lib/utils/icon_utils';

describe('Icon utils', () => {
  describe('getSvgIconPathContent', () => {
    let spriteIcons;

    beforeAll(() => {
      spriteIcons = gon.sprite_icons;
      gon.sprite_icons = 'mockSpriteIconsEndpoint';
    });

    afterAll(() => {
      gon.sprite_icons = spriteIcons;
    });

    let axiosMock;
    let mockEndpoint;
    let getIcon;
    const mockName = 'mockIconName';
    const mockPath = 'mockPath';

    beforeEach(() => {
      axiosMock = new MockAdapter(axios);
      mockEndpoint = axiosMock.onGet(gon.sprite_icons);
      getIcon = iconUtils.getSvgIconPathContent(mockName);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('extracts svg icon path content from sprite icons', done => {
      mockEndpoint.replyOnce(
        200,
        `<svg><symbol id="${mockName}"><path d="${mockPath}"/></symbol></svg>`,
      );
      getIcon
        .then(path => {
          expect(path).toBe(mockPath);
          done();
        })
        .catch(done.fail);
    });

    it('returns null if icon path content does not exist', done => {
      mockEndpoint.replyOnce(200, ``);
      getIcon
        .then(path => {
          expect(path).toBe(null);
          done();
        })
        .catch(done.fail);
    });

    it('returns null if an http error occurs', done => {
      mockEndpoint.replyOnce(500);
      getIcon
        .then(path => {
          expect(path).toBe(null);
          done();
        })
        .catch(done.fail);
    });
  });
});
