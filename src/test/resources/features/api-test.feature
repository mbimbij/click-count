Feature: API test

  Scenario: healthcheck is ok
    When we call the REST endpoint "/healthcheck"
    Then the REST response is as following:
      | httpStatus | 200 |
      | body       | ok  |