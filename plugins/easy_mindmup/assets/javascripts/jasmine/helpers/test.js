(function () {
  /**
   * Class responsible for Jasmine testing
   * @param {MindMup} ysy
   * @property {MindMup} ysy
   * @constructor
   */
  function JasmineTests(ysy) {
    this.ysy = ysy;
    this._redrawRequested = true;
    this.jasmineStarted = false;
    this.startCounter = 0;
    this.beatCallbacks = [];
    this.extraTestNames = [];
    this.extraTestFunctions = [];
    this.init(ysy);
  }

  /**
   *
   * @param {MindMup} ysy
   */
  JasmineTests.prototype.init = function (ysy) {
    ysy.eventBus.register("TreeLoaded",function () {
      if (!this.jasmineStarted) {
        this.jasmineStarted = true;
        window.jasmine.jasmineStart(ysy);
      }
    });
    ysy.repainter.redrawMe(this);
    this.loadExtraTests();
  };
  JasmineTests.prototype._render = function () {
    if (this.beatCallbacks.length) {
      var newCallbacks = [];
      for (var i = 0; i < this.beatCallbacks.length; i++) {
        var callPack = this.beatCallbacks[i];
        if (callPack.rounds === 1) {
          callPack.callback();
        } else {
          callPack.rounds--;
          newCallbacks.push(callPack);
        }
      }
      this.beatCallbacks = newCallbacks;
      if(newCallbacks.length){
        this.ysy.repainter.redrawMe(this);
      }
    }
  };
  JasmineTests.prototype.fewBeatsAfter = function (callback, count) {
    if (count === undefined) count = 2;
    this.beatCallbacks.push({callback: callback, rounds: count});
    this.ysy.repainter.redrawMe(this);
  };
  JasmineTests.prototype.loadExtraTests = function () {
    var self = this;
    describe("(EXTRA)", function () {
      for (var i = 0; i < self.extraTestFunctions.length; i++) {
        self.extraTestFunctions[i]();
      }
    });
  };
  JasmineTests.prototype.parseResult = function () {
    var specs = window.jsApiReporter.specs();
    var shortReport = "";
    var report = "";
    var allPassed = true;
    var result = "";
    for (var i = 0; i < specs.length; i++) {
      var spec = specs[i];
      if (spec.status === "passed") {
        shortReport += ".";
      } else {
        allPassed = false;
        shortReport += "X";
        report += "__TEST " + spec.fullName + "______\n";
        for (var j = 0; j < spec.failedExpectations.length; j++) {
          var fail = spec.failedExpectations[j];
          var split = fail.stack.split("\n");
          result += window.location + "\n";
          report += "   " + fail.message + "\n";
          for (var k = 1; k < split.length; k++) {
            if (split[k].indexOf("/jasmine_lib/") > -1) break;
            report += split[k] + "\n";
          }
        }
      }
    }
    if (allPassed) {
      return "success";
    }
    result += " RESULTS: " + shortReport + "\n" + report;
    $("#content").text(result.replace("\n", "<br>"));
    return result;
  };
  easyMindMupClasses.JasmineTests = JasmineTests;
})();
window.describeExtra = function (file, func) {
  if (file.indexOf("/") === -1) {
    file = "easy_mindmup/" + file
  }
  jasmine.ysyInstance.tests.extraTestNames.push(file);
  jasmine.ysyInstance.tests.extraTestFunctions.push(function () {
    describe(file, func);
  });
};
