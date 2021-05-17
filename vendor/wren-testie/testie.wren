import "../wren-assert/Assert" for Assert
import "random" for Random
import "io" for Stdout
import "os" for Process
import "./vendor/colors" for Colors as Color
import "./src/reporter" for CuteReporter
import "./src/expect" for Expect
var RND = Random.new()

class Test {
    construct new(name, fn) {
        _name = name
        _fn = fn
        _skip = false
    }
    skip { _skip }
    name { _name }
    fn { _fn }
    skip() { _skip = true }
}

class Testie {
    construct new(name, fn) {
        _tests = []
        _skips = []
        _name = name
        _fails = 0
        _afterEach = _beforeEach = Fn.new {}
        fn.call(this, Skipper.new(this))
    }
    static test(name, fn) { Testie.new(name,fn).run() }
    afterEach(fn) { _afterEach = fn }
    beforeEach(fn) { _beforeEach = fn }
    reporter=(v){ _reporter = v }
    reporter { _reporter || CuteReporter }

    // aliases
    should(name, fn) { test(name,fn) }
    describe(name, fn) { context(name,fn) }

    // core API
    test(name, fn) { _tests.add(Test.new(name, fn)) }
    skip(name, fn) { test(name,fn).skip() }
    context(name, fn) {
        _tests.add(name)
        fn.call()
    }
    run() {
        if (!(_tests[0] is String)) { _name = _name + "\n" }
        var r = reporter.new(_name)
        r.start()

        var i = 0
        var first_error
        for (test in _tests) {
            if (test is String) {
                r.section(test)
                continue
            }
            if (test.skip) {
                r.skip(test.name)
                continue
            }

            _beforeEach.call()
            var error = Fiber.new(test.fn).try()
            if (error) {
                if (first_error == null) first_error = i
                _fails = _fails + 1
                r.fail(test.name, error)
            } else {
                r.success(test.name)
            }
            _afterEach.call()
            i = i + 1
        }
        r.done()
        Stdout.flush()

        if (first_error && false) {
            var test = _tests[first_error]
            System.print(Color.BLACK + Color.BOLD + "--- TEST " + "-" * 66 + Color.RESET)
            System.print("%(test.name)\n")
            System.print(Color.BLACK + Color.BOLD + "--- STACKTRACE " + "-" * 60 + Color.RESET)
            Stdout.flush()
            Fiber.new(test.fn).call()
        }
        if (_fails > 0) Fiber.abort("Failing tests.")
    }
}




class Skipper {
    construct new(that) {
        _that = that
    }
    test(a,b) { _that.skip(a,b) }
    should(a,b) { _that.skip(a,b) }
}

