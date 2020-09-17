describeExtra("easy_gantt_pro/global_gantt", function () {
  describe("PRO Global gantt", function () {
    it("should fail anywhere but global gantt", function () {
      expect(ysy.settings.global).toBe(true);
      expect(ysy.settings.isGantt).toBe(true);
    });
  });
});