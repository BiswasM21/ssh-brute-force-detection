name: Bug Report
description: Report a bug to help us improve
title: "[Bug] "
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        ## Bug Description
        Please describe the bug in detail.

  - type: textarea
    id: description
    attributes:
      label: Description
      placeholder: A clear and concise description of the bug
    validations:
      required: true

  - type: dropdown
    id: component
    attributes:
      label: Component
      options:
        - Splunk App
        - Docker
        - Vagrant
        - Attack Scripts
        - Dashboards
        - Alerts
        - Documentation
    validations:
      required: true

  - type: textarea
    id: steps
    attributes:
      label: Steps to Reproduce
      placeholder: |
        1. Go to '...'
        2. Run '...'
        3. See error
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: Actual behavior
    validations:
      required: true

  - type: input
    id: environment
    attributes:
      label: Environment
      placeholder: |
        OS: Ubuntu 22.04
        Docker version: 24.0
        Splunk version: 9.0

---

name: Feature Request
description: Suggest a new feature for the project
title: "[Feature] "
labels: ["enhancement"]
body:
  - type: markdown
    attributes:
      value: |
        ## Feature Description
        Describe the feature you'd like to request.

  - type: textarea
    id: feature
    attributes:
      label: Feature
      placeholder: A clear and concise description of the feature
    validations:
      required: true

  - type: textarea
    id: motivation
    attributes:
      label: Motivation
      placeholder: Why would this feature be useful?

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      placeholder: Any alternative solutions you've considered
