### Unreleased

### 2.0.0 - 2020-03-16

* breaking changes
  * Raises exception if shadowing an existing `#call` method in a dependency (#15)

### 1.0.3 - 2020-03-16

* enhancements
  * Added GitHub Actions as CI (#9)

* bug fixes
  * Fixed a bug that wouldn't pass a block if `#call` was aliased (#7)

### 1.0.2 - 2020-03-02

* security
  * Bump `rake` to 12.3.3 (#11)
