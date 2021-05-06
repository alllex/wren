import "../wren-assert/Assert" for Assert
import "random" for Random
var RND = Random.new()
var SAD_EMOJI = ["😡","👺","👿","🙀","💩","😰","😤","😬"]


class Testie {
    construct new(name, fn) {
        _tests = []
        _skips = []
        _name = name
        _fails = 0
        _beforeEach = Fn.new {}
        fn.call(this, Skipper.new(this))
    }

    beforeEach(fn) { _beforeEach = fn }
    test(name, fn) { _tests.add([name, fn]) }
    should(name, fn) { test(name,fn) }
    skip(name, fn) { _skips.add([name,fn]) }
    reporter=(v){ _reporter = v }
    reporter { _reporter || Reporter }
    static test(name, fn) { Testie.new(name,fn).run() }
    describe(name, fn) {
        _tests.add(name)
        fn.call()
    }
    run() {
        var r = reporter.new(_name)
        r.start()

        for (test in _tests) {
            if (test is String) {
                r.section(test)
                continue
            }

            var name = test[0]
            var fn = test[1]
            _beforeEach.call()
            var fiber = Fiber.new(fn)
            fiber.try()
            if (fiber.error) {
                _fails = _fails + 1
                r.fail(name, fiber.error)
            } else {
                r.success(name)
            }
        }
        for (test in _skips) {
            var name = test[0]
            r.skip(name)
        }
        r.done()
        if (_fails > 0) Fiber.abort("Failing test")
    }
}

class Expect {
    construct new(value) {
        _value = value
    }
    static that(v) { Expect.new(v) }
    toEqual(v) { toBe(v) }
    equalMaps_(v) {
        if (_value.count != v.count) return false
        for (k in _value.keys) {
            if (_value[k] != v[k]) return false
        }
        return true
    }
    toIncludeSameItemsAs(v) {
        if (_value.count != v.count) return false
        for (item in _value) {
            if (!v.contains(item)) return false
        }
        return true
    }
    equalLists_(v) {
        if (_value.count != v.count) return false
        for (i in 0...v.count) {

            if (_value[i] != v[i]) {
                return false
            }
        }
        return true
    }
    abortsWith(err) {
        var f = Fiber.new { _value.call() }
        var result = f.try()
        if (result!=err) {
            Fiber.abort("Expected error '%(err)' but got none")
        }
    }
    toBeGreaterThanOrEqual(v) {
        if (_value >= v) return
        Fiber.abort("Expected %(v) to be greater than or equal to %(_value)")
    }
    toBeLessThanOrEqual(v) {
        if (_value <= v) return
        Fiber.abort("Expected %(v) to be less than or equal to %(_value)")
    }
    printValue(v) {
        if (v is String) {
            return "`%(v)`"
        } else if (v is List) {
            return "[" + v.map {|x| printValue(x) }.join(", ") +  "]"
        } else {
            return "%(v)"
        }
    }
    toBe(v) {
        if (_value is String || v is String) {
            if (_value == v) return

            var err=""
            err = err + "\rReceived: "
            err = err + printValue(_value) + "\n"
            err = err + "\nExpected: "
            err = err + printValue(v)
            Fiber.abort("%(err)\nShould match.")
        }
        if (_value is List && v is List) {
            if (!equalLists_(v)) {
                Fiber.abort("Expected list %(printValue(_value)) to be %(printValue(v))")
            }
            return
        }
        if (v is Map && _value is Map) {
            if (!equalMaps_(v)) {
                Fiber.abort("Expected %(_value) to be %(v)")
            }
            return
        }
        if (_value != v) {
            Fiber.abort("Expected %(_value) to be %(v)")
        }
    }
}

class Reporter {
    construct new(name) {
        _name = name
        _fail = _skip = _success = 0
    }
    start() { System.print(_name) }
    skip(name) {
        _skip = _skip + 1
        System.print("  🔹 [skip] %(name)")
    }
    section(name) { System.print("\n  %(name)\n") }
    fail(name, error) {
        _fail = _fail + 1
        System.print("  ❌ %(name) \n     %(error)\n")
    }
    success(name) {
        _success = _success + 1
        System.print("  ✅ %(name)")
    }
    sadEmotion { SAD_EMOJI[RND.int(SAD_EMOJI.count)] }
    done() {
        var overall = "💯"
        if (_fail > 0) overall = "❌ %(sadEmotion)"
        System.print("\n  %(overall) ✓ %(_success) successes, ✕ %(_fail) failures, ☐ %(_skip) skipped\n")
    }
}

class Skipper {
    construct new(that) {
        _that = that
    }
    test(a,b) { _that.skip(a,b) }
    should(a,b) { _that.skip(a,b) }
}

