import "./hamming" for Hamming
import "./vendor/wren-testie/testie" for Testie, Assert, Expect

Testie.test("Hamming") { |do, skip|
  do.test("empty strands") {
    Expect.that(Hamming.compute("", "")).toEqual(0)
  }

  skip.test("single letter identical strands") {
    Expect.that(Hamming.compute("A", "A")).toEqual(0)
  }

  skip.test("single letter different strands") {
    Expect.that(Hamming.compute("G", "T")).toEqual(1)
  }

  skip.test("long identical strands") {
    Expect.that(Hamming.compute("GGACTGAAATCTG", "GGACTGAAATCTG")).toEqual(0)
  }

  skip.test("long different strands") {
    Expect.that(Hamming.compute("GGACGGATTCTG", "AGGACGGATTCT")).toEqual(9)
  }

  skip.test("disallow first strand longer") {
    Expect.that {
      Hamming.compute("AATG", "AAA")
    }.abortsWith("left and right strands must be of equal length")
  }

  skip.test("disallow second strand longer") {
    Expect.that {
      Hamming.compute("ATA", "AGTG")
    }.abortsWith("left and right strands must be of equal length")
  }

  skip.test("disallow left empty strand") {
    Expect.that {
      Hamming.compute("", "G")
    }.abortsWith("left strand must not be empty")
  }

  skip.test("disallow right empty strand") {
    Expect.that {
      Hamming.compute("G", "")
    }.abortsWith("right strand must not be empty")
  }
}