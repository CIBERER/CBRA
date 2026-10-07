# Groovy implementation guidelines

These guidelines apply to Groovy source and to Groovy expressions embedded in Nextflow scripts,
configuration, and tests. Nextflow is a specialized language with stricter semantics than general
Groovy; [`nextflow.md`](./nextflow.md) takes precedence for Nextflow code.

The keywords "MUST", "MUST NOT", "SHOULD", etc. are to be interpreted as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Declarations and scope

- Variables MUST be declared with `def` or an explicit type. Undeclared assignments can create
  unintended fields or shared state and MUST NOT be used.
- Use the narrowest practical scope. A value SHOULD be declared immediately before the code that
  consumes it.
- Values SHOULD be immutable by convention. Use `final` for constants and fields whose references
  must not change.
- Global state and `@Field` MUST NOT be introduced unless lifecycle and concurrency behavior are
  intentional, documented, and tested.
- Use `camelCase` for variables and methods, `PascalCase` for classes, and `UPPER_SNAKE_CASE` for
  constants, unless a framework convention requires another form.

## Types and public contracts

- Use `def` when the inferred type is obvious and local. Use explicit parameter and return types when
  they clarify a public API, disambiguate overloads, or enable useful static checking.
- Domain concepts SHOULD use dedicated classes or well-documented maps. Do not pass around long,
  weakly defined positional lists outside narrow pipeline transformations.
- Conversions from external text MUST be explicit. Validate before calling methods such as
  `toInteger()`, `toBoolean()`, or enum conversion.
- Use `==` and `!=` for value equality. Use `is()` only when object identity is the intended test.
- Numeric code SHOULD make precision and conversion intentional. Do not rely on implicit coercion
  where integer, decimal, or floating-point behavior changes the result.

## Strings and interpolation

- Use single-quoted strings for literals and double-quoted strings only when interpolation is needed.
- Use `${expression}` for interpolated expressions and whenever braces remove ambiguity.
- Do not use a `GString` as a map key or persistent identifier; convert it to `String` first.
- Multiline strings SHOULD use the quoting form that matches interpolation requirements and
  `stripIndent()` or `stripMargin()` when indentation is part of source readability but not content.
- Untrusted values MUST NOT be interpolated into shell, SQL, or other executable text without the
  target API's argument binding or escaping mechanism.

```groovy
def sampleId = 'sample-01'
def message = "Processing ${sampleId}"
def key = "result-${sampleId}".toString()
```

## Collections and maps

- Prefer collection literals (`[]`, `[:]`) and Groovy collection methods over manual indexing and
  accumulator loops.
- Use `collect` for transformation, `findAll` for filtering, `find` for one match, `any`/`every` for
  predicates, `groupBy` for grouping, and `collectEntries` for map construction.
- A transformation SHOULD return a new collection. Do not mutate a collection while iterating over it.
- Use `each` for side effects only. A value-producing operation SHOULD use `collect` or another
  operator that communicates the result.
- Closure parameters SHOULD be explicit for maps, tuples, nested closures, or any operation where
  `it` is not immediately clear.
- Test key presence with `containsKey()` when `false`, `0`, an empty value, and a missing key have
  different meanings.
- Clone or construct a new map before adding fields to metadata received from another component.

```groovy
def activeNames = samples
    .findAll { sample -> sample.active }
    .collect { sample -> sample.name }

def enrichedMeta = meta + [attempt: attempt]
```

## Closures

- Closures SHOULD be short, focused, and free of hidden side effects.
- Name closure parameters instead of relying on implicit `it` when the closure spans multiple lines
  or handles structured data.
- Do not mutate captured variables from concurrent or asynchronous code. Return a value and compose
  the result instead.
- Closure delegation (`delegate`, `owner`, `resolveStrategy`) MUST NOT be changed unless implementing
  a deliberate DSL boundary with tests.
- A closure's implicit return is appropriate for a single expression. Use an explicit `return` in a
  multi-branch method or closure when it materially improves clarity.

```groovy
def normalize = { String value ->
    value.trim().toLowerCase()
}
```

## Nulls and truth

- Use `?.` when `null` is an expected value and propagating `null` is the intended behavior.
- Use the Elvis operator (`?:`) only when all Groovy-false values (`null`, `false`, zero, empty strings,
  and empty collections) should select the fallback.
- Use an explicit null check when `false`, zero, or an empty value is valid.
- Required data SHOULD fail validation close to the boundary instead of producing a later
  `NullPointerException`.

```groovy
def retries = config.retries != null ? config.retries : 3
def label = sample?.label ?: 'unknown'
```

## Control flow and methods

- Prefer guard clauses to deeply nested conditionals.
- Methods SHOULD do one cohesive job and keep side effects visible in their names and call sites.
- Complex expressions SHOULD be decomposed into named intermediate values.
- Use ranges and collection methods where they improve intent, but prefer straightforward control
  flow when functional chains become difficult to read.
- Exhaustive choices SHOULD include an explicit failure for unsupported values.
- Assertions SHOULD verify programmer invariants and tests, not replace validation of user input.

## Exceptions and resources

- Throw exceptions with actionable context. Preserve the original exception as the cause when
  translating it at an abstraction boundary.
- Catch the narrowest exception that can be handled. Do not catch `Throwable`, swallow exceptions,
  or return a misleading fallback after an unexpected failure.
- Close I/O resources deterministically with `withCloseable`, `withReader`, `withWriter`, or another
  appropriate resource-scoped API.
- External processes SHOULD use a framework abstraction that handles arguments, streams, exit status,
  and cancellation. In Nextflow code, external commands MUST run in a `process`, not through
  Groovy's `String.execute()`.

## Dynamic language features

- Reflection, runtime metaclass mutation, `methodMissing`, `propertyMissing`, and ad hoc monkey
  patching SHOULD be avoided. Use explicit interfaces, methods, or adapters.
- Operator overloading SHOULD be used only when its meaning is conventional for the domain.
- Do not depend on implicit coercions or optional parentheses when they make a call ambiguous.
- Framework DSL syntax MAY omit parentheses where established by the framework; ordinary method calls
  SHOULD retain them when doing so improves readability.

## Formatting and documentation

- Follow the repository formatter. In the absence of one, use four spaces, opening braces on the same
  line, one statement per line, and no semicolons.
- Comments SHOULD explain constraints, intent, or non-obvious tradeoffs. They MUST NOT narrate syntax.
- Public classes and methods SHOULD use Groovydoc when their contract is not obvious from the name and
  signature.
- Keep imports explicit and remove unused imports. Wildcard imports SHOULD NOT be introduced outside
  established framework conventions.

## Validation

- Run the repository's formatter, compiler or linter, and tests after changing Groovy code.
- Tests SHOULD cover null and empty inputs, false-like values, collection shape, exceptional paths,
  and any behavior that depends on dynamic dispatch or coercion.
- Groovy embedded in Nextflow MUST also pass the Nextflow linter and the repository's workflow tests.

## References

- [Groovy language specification](https://docs.groovy-lang.org/latest/html/documentation/)
- [Groovy closures](https://docs.groovy-lang.org/latest/html/documentation/core-closures.html)
- [Groovy development kit](https://docs.groovy-lang.org/latest/html/documentation/core-gdk.html)
- [Groovy style guide](https://docs.groovy-lang.org/latest/html/documentation/style-guide.html)
