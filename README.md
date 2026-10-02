# Bookshop Service

## Prerequisites

- Node.js 22 LTS or 24 LTS
- npm 10+
- Maven
- Java / JDK

Example install commands on macOS (Homebrew):

```bash
brew install node@22
brew install openjdk
brew install maven
```

Install project packages:

```bash
cd bookshop-service
npm install
```

All JavaScript dependencies, including the SAP packages, are resolved from the
public npm registry. Java dependencies are resolved from Maven Central; an SAP
Artifactory account is not required. Keep the committed lockfiles so local and
Cloud Foundry builds use the same tested dependency versions.

For an MTA build, clone `bookshop-service` and `bookshop-ui` as sibling
directories because `mta.yaml` builds the UI from `../bookshop-ui`.

## Run locally

```bash
cd bookshop-service
npm run init
npm start
```

Optional check:

```bash
cd bookshop-service
npm run verify
```

## Main features

- Book catalog, authors, categories, and publishers
- Inventory attention and restock request workflow
- Draft-based restock request processing with history
- Sales, reviews, and stock movement APIs
