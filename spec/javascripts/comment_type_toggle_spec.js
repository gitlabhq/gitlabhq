import CommentTypeToggle from '~/comment_type_toggle';
import '~/droplab/droplab';
import '~/droplab/plugins/input_setter';

describe('CommentTypeToggle', function () {
  describe('class constructor', function () {
    beforeEach(function () {
      this.trigger = {};
      this.list = {};
      this.input = {};
      this.button = {};

      this.commentTypeToggle = new CommentTypeToggle(
        this.trigger,
        this.list,
        this.input,
        this.button,
      );
    });

    it('should set .trigger', function () {
      expect(this.commentTypeToggle.trigger).toBe(this.trigger);
    });

    it('should set .list', function () {
      expect(this.commentTypeToggle.list).toBe(this.list);
    });

    it('should set .input', function () {
      expect(this.commentTypeToggle.input).toBe(this.input);
    });

    it('should set .button', function () {
      expect(this.commentTypeToggle.button).toBe(this.button);
    });
  });

  describe('initDroplab', function () {
    beforeEach(function () {
      this.commentTypeToggle = {
        trigger: {},
        list: {},
        input: {},
        button: {},
      };

      this.droplab = jasmine.createSpyObj('droplab', ['addHook']);

      spyOn(window, 'DropLab').and.returnValue(this.droplab);

      this.initDroplab = CommentTypeToggle.prototype.initDroplab.call(this.commentTypeToggle);
    });

    it('should instantiate a DropLab instance', function () {
      expect(window.DropLab).toHaveBeenCalled();
    });

    it('should set .droplab', function () {
      expect(this.commentTypeToggle.droplab).toBe(this.droplab);
    });

    it('should call DropLab.prototype.addHook', function () {
      expect(this.droplab.addHook).toHaveBeenCalledWith(
        this.commentTypeToggle.trigger,
        this.commentTypeToggle.list,
        [droplabInputSetter],
        {
          droplabInputSetter: [{
            input: this.commentTypeToggle.input,
            valueAttribute: 'data-value',
          }, {
            input: this.commentTypeToggle.button,
            valueAttribute: 'data-button-text',
          }],
        },
      );
    });
  });
});
