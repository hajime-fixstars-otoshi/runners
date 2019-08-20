NodeHarness::Testing::Smoke.add_test("basic", {
    guid: "test-guid",
    timestamp: :_,
    type: "success",
    issues: [
      {
        id: "sample.in_array_without_3rd_param",
        path: "index.php",
        location: { :start_line => 2, :start_column => 5, :end_line => 2, :end_column => 34 },
        object: {
          id: "sample.in_array_without_3rd_param",
          message: "Specify 3rd parameter explicitly when calling in_array to avoid unexpected comparison results.",
          justifications: [],
        },
      },
      {
        id: "sample.var_dump",
        path: "index.php",
        location: { :start_line => 3, :start_column => 5, :end_line => 3, :end_column => 21 },
        object: {
          id: "sample.var_dump",
          message: "Do not use var_dump.",
          justifications: ["Allowed when debugging"],
        },
      },
    ],
    analyzer: {
      name: "Phinder",
      version: "0.9.2"
    }
})

NodeHarness::Testing::Smoke.add_test("options", {
  guid: "test-guid",
  timestamp: :_,
  type: "success",
  issues: [
    {
      id: "sample.in_array_without_3rd_param",
      path: "src/index.php",
      location: { :start_line => 2, :start_column => 5, :end_line => 2, :end_column => 33 },
      object: {
        id: "sample.in_array_without_3rd_param",
        message: "Specify 3rd parameter explicitly when calling in_array to avoid unexpected comparison results.",
        justifications: [],
      },
    },
    {
      id: "sample.var_dump",
      path: "src/index.php",
      location: { :start_line => 3, :start_column => 5, :end_line => 3, :end_column => 21 },
      object: {
        id: "sample.var_dump",
        message: "Do not use var_dump.",
        justifications: [],
      },
    },
  ],
  analyzer: {
    name: "Phinder",
    version: "0.9.2"
  }
})

NodeHarness::Testing::Smoke.add_test("test_failed", {
  guid: "test-guid",
  timestamp: :_,
  type: "success",
  issues: [
    {
      id: "sample.in_array_without_3rd_param",
      path: "index.php",
      location: { :start_line => 2, :start_column => 5, :end_line => 2, :end_column => 33 },
      object: {
        id: "sample.in_array_without_3rd_param",
        message: "Specify 3rd parameter explicitly when calling in_array to avoid unexpected comparison results.",
        justifications: [],
      },
    },
  ],
  analyzer: {
    name: "Phinder",
    version: "0.9.2"
  }
}, warnings: [
  { message: <<~MESSAGE, file: "phinder.yml" }
    Phinder configuration validation failed.
    Check the following output by `phinder test` command.

    `in_array(2, $arr, false)` does not match the rule sample.in_array_without_3rd_param but should match that rule.
    `in_array(4, $arr)` matches the rule sample.in_array_without_3rd_param but should not match that rule.
  MESSAGE
])

NodeHarness::Testing::Smoke.add_test("analyzer_failed", {
  guid: "test-guid",
  timestamp: :_,
  type: "failure",
  message: <<~MESSAGE,
    1 error occurred:

    InvalidRule: Invalid id value found in 1st rule in phinder.yml
  MESSAGE
  analyzer: {
    name: "Phinder",
    version: "0.9.2"
  }
})

NodeHarness::Testing::Smoke.add_test("invalid_runner_config", {
  guid: "test-guid",
  timestamp: :_,
  type: "failure",
  message: "Invalid configuration in sideci.yml: unknown attribute at config: $.linter.phinder",
  analyzer: nil,
})

NodeHarness::Testing::Smoke.add_test("ctp_file", {
  guid: "test-guid",
  timestamp: :_,
  type: "success",
  issues: [
    {
      object: {
        id: "sample.in_array_without_3rd_param",
        message: "Specify 3rd parameter explicitly when calling in_array to avoid unexpected comparison results.",
        justifications: []
      },
      id: "sample.in_array_without_3rd_param",
      path: "view.ctp",
      location: { start_line: 3, start_column: 9, end_line: 3, end_column: 38 }
    }
  ],
  analyzer: {
    name: "Phinder",
    version: "0.9.2"
  }
})

NodeHarness::Testing::Smoke.add_test("config_not_found", {
  guid: "test-guid",
  timestamp: :_,
  type: "success",
  issues: [],
  analyzer: {
    name: "Phinder",
    version: "0.9.2"
  }
}, warnings: [
  { message: <<~MESSAGE, file: "phinder.yml" }
    File not found: `phinder.yml`. This file is necessary for analysis.
    See also: https://help.sider.review/tools/php/phinder
  MESSAGE
])