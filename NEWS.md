# tidyvisor 0.1.0

* First release. tidyvisor is the statistical adviser shared by tidydiversity
  and tidymapr, moved into a package of its own so that one `tidyvisor()`
  serves both, whichever is loaded.
* `tidyvisor()` advises on data (`advise()`) and interprets fitted results
  (`interpret()`).
* `register_advisor()` lets any package add an adviser; `advisors()` lists
  them. Advisers for tidydiversity (community ecology) and tidymapr (spatial
  ecology) are built in and used when those packages are installed.
