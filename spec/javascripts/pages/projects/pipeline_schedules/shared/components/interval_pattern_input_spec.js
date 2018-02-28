import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';

Vue.use(Translate);

const IntervalPatternInputComponent = Vue.extend(IntervalPatternInput);
const inputNameAttribute = 'schedule[cron]';

const cronIntervalPresets = {
  everyDay: '0 4 * * *',
  everyWeek: '0 4 * * 0',
  everyMonth: '0 4 1 * *',
};

window.gl = window.gl || {};

window.gl.pipelineScheduleFieldErrors = {
  updateFormValidityState: () => {},
};

describe('Interval Pattern Input Component', function () {
  describe('when prop initialCronInterval is passed (edit)', function () {
    describe('when prop initialCronInterval is custom', function () {
      beforeEach(function () {
        this.initialCronInterval = '1 2 3 4 5';
        this.intervalPatternComponent = new IntervalPatternInputComponent({
          propsData: {
            initialCronInterval: this.initialCronInterval,
          },
        }).$mount();
      });

      it('is initialized as a Vue component', function () {
        expect(this.intervalPatternComponent).toBeDefined();
      });

      it('prop initialCronInterval is set', function () {
        expect(this.intervalPatternComponent.initialCronInterval).toBe(this.initialCronInterval);
      });

      it('sets isEditable to true', function (done) {
        Vue.nextTick(() => {
          expect(this.intervalPatternComponent.isEditable).toBe(true);
          done();
        });
      });
    });

    describe('when prop initialCronInterval is preset', function () {
      beforeEach(function () {
        this.intervalPatternComponent = new IntervalPatternInputComponent({
          propsData: {
            inputNameAttribute,
            initialCronInterval: '0 4 * * *',
          },
        }).$mount();
      });

      it('is initialized as a Vue component', function () {
        expect(this.intervalPatternComponent).toBeDefined();
      });

      it('sets isEditable to false', function (done) {
        Vue.nextTick(() => {
          expect(this.intervalPatternComponent.isEditable).toBe(false);
          done();
        });
      });
    });
  });

  describe('when prop initialCronInterval is not passed (new)', function () {
    beforeEach(function () {
      this.intervalPatternComponent = new IntervalPatternInputComponent({
        propsData: {
          inputNameAttribute,
        },
      }).$mount();
    });

    it('is initialized as a Vue component', function () {
      expect(this.intervalPatternComponent).toBeDefined();
    });

    it('prop initialCronInterval is set', function () {
      const defaultInitialCronInterval = '';
      expect(this.intervalPatternComponent.initialCronInterval).toBe(defaultInitialCronInterval);
    });

    it('sets isEditable to true', function (done) {
      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.isEditable).toBe(true);
        done();
      });
    });
  });

  describe('User Actions', function () {
    beforeEach(function () {
      // For an unknown reason, some browsers do not propagate click events
      // on radio buttons in a way Vue can register. So, we have to mount
      // to a fixture.
      setFixtures('<div id="my-mount"></div>');

      this.initialCronInterval = '1 2 3 4 5';
      this.intervalPatternComponent = new IntervalPatternInputComponent({
        propsData: {
          initialCronInterval: this.initialCronInterval,
        },
      }).$mount('#my-mount');
    });

    it('cronInterval is updated when everyday preset interval is selected', function (done) {
      this.intervalPatternComponent.$el.querySelector('#every-day').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.cronInterval).toBe(cronIntervalPresets.everyDay);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').value).toBe(cronIntervalPresets.everyDay);
        done();
      });
    });

    it('cronInterval is updated when everyweek preset interval is selected', function (done) {
      this.intervalPatternComponent.$el.querySelector('#every-week').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.cronInterval).toBe(cronIntervalPresets.everyWeek);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').value).toBe(cronIntervalPresets.everyWeek);

        done();
      });
    });

    it('cronInterval is updated when everymonth preset interval is selected', function (done) {
      this.intervalPatternComponent.$el.querySelector('#every-month').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.cronInterval).toBe(cronIntervalPresets.everyMonth);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').value).toBe(cronIntervalPresets.everyMonth);
        done();
      });
    });

    it('only a space is added to cronInterval (trimmed later) when custom radio is selected', function (done) {
      this.intervalPatternComponent.$el.querySelector('#every-month').click();
      this.intervalPatternComponent.$el.querySelector('#custom').click();

      Vue.nextTick(() => {
        const intervalWithSpaceAppended = `${cronIntervalPresets.everyMonth} `;
        expect(this.intervalPatternComponent.cronInterval).toBe(intervalWithSpaceAppended);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').value).toBe(intervalWithSpaceAppended);
        done();
      });
    });

    it('text input is disabled when preset interval is selected', function (done) {
      this.intervalPatternComponent.$el.querySelector('#every-month').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.isEditable).toBe(false);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').disabled).toBe(true);
        done();
      });
    });

    it('text input is enabled when custom is selected', function (done) {
      this.intervalPatternComponent.$el.querySelector('#every-month').click();
      this.intervalPatternComponent.$el.querySelector('#custom').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.isEditable).toBe(true);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').disabled).toBe(false);
        done();
      });
    });
  });
});
