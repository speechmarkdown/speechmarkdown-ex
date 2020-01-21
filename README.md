# SpeechMarkdown

[Speech Markdown](https://www.speechmarkdown.org/) transpiler for Elixir

This library converts text in the Speech Markdown format to
[SSML](https://www.w3.org/TR/speech-synthesis11/) for processing by
Text-To-Speech APIs, etc.

## Status
[![Hex](http://img.shields.io/hexpm/v/speechmarkdown.svg?style=flat)](https://hex.pm/packages/speechmarkdown)
[![CircleCI](https://circleci.com/gh/spokestack/speechmarkdown-ex.svg?style=shield)](https://circleci.com/gh/spokestack/speechmarkdown-ex)
[![Coverage](https://coveralls.io/repos/github/spokestack/speechmarkdown-ex/badge.svg)](https://coveralls.io/github/spokestack/speechmarkdown-ex)

The API reference is available [here](https://hexdocs.pm/speechmarkdown/).

## Installation

```elixir
def deps do
  [
    {:speechmarkdown, "~> 0.1"}
  ]
end
```

## Usage

```elixir
iex> SpeechMarkdown.Transpiler.transpile!("You say pecan, I say (pecan)[/pɪˈkɑːn/].")
```

```xml
<?xml version="1.0"?>
<speak>You say pecan, I say <phoneme alphabet="ipa" ph="pɪˈkɑːn">pecan</phoneme>.</speak>
```

The following Speech Markdown modifiers are supported:

* [break](https://www.speechmarkdown.org/syntax/break/)
* [characters](https://www.speechmarkdown.org/syntax/characters/)
* [ipa](https://www.speechmarkdown.org/syntax/ipa/)
* [number](https://www.speechmarkdown.org/syntax/number/)

## License

Copyright 2020 Spokestack, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
