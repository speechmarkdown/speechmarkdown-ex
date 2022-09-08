# SpeechMarkdown

[Speech Markdown](https://www.speechmarkdown.org/) transpiler for Elixir.

This library converts text in the Speech Markdown format to
[SSML](https://www.w3.org/TR/speech-synthesis11/) for processing by
Text-To-Speech APIs, etc.

## Status

[![Hex](http://img.shields.io/hexpm/v/speechmarkdown.svg?style=flat)](https://hex.pm/packages/speechmarkdown)
[![Test](https://github.com/speechmarkdown/speechmarkdown-ex/actions/workflows/test.yml/badge.svg)](https://github.com/speechmarkdown/speechmarkdown-ex/actions/workflows/test.yml)
[![Coverage](https://coveralls.io/repos/github/speechmarkdown/speechmarkdown-ex/badge.svg)](https://coveralls.io/github/speechmarkdown/speechmarkdown-ex)

The API reference is available [here](https://hexdocs.pm/speechmarkdown/).

## Installation

```elixir
def deps do
  [
    {:speechmarkdown, "~> 0.2"}
  ]
end
```

## Usage

As of version 0.2, the entire Speech Markdown specification is
supported and unified over the multiple implementations (JS, Elixir)
under a single collection of [reference test cases](https://github.com/speechmarkdown/speechmarkdown-test-files).

```elixir
iex> SpeechMarkdown.to_ssml!("You say pecan, I say (pecan)[/pɪˈkɑːn/].")

"<speak>You say pecan, I say <phoneme alphabet=\"ipa\" ph=\"pɪˈkɑːn\">pecan</phoneme>.</speak>"
```

The library supports the `:general`, `:alexa` and `:google` variants
of SSML. Some Speech Markdown tags are only available on those
platforms, e.g. `[whisper]`:

```elixir
iex> SpeechMarkdown.to_ssml!("#[whisper] I can see dead people", variant: :alexa)
"<speak><amazon:effect name=\"whispered\">I can see dead people</amazon:effect></speak>"
```

The following Speech Markdown modifiers are supported:

- [break](https://www.speechmarkdown.org/syntax/break/)
- [characters](https://www.speechmarkdown.org/syntax/characters/)
- [ipa](https://www.speechmarkdown.org/syntax/ipa/)
- [number](https://www.speechmarkdown.org/syntax/number/)

## Extensions to speech markdown

The following additional Speech Markdown syntax is supported:

- `$[x]` inserts an [SSML Mark][mark] named `x`

[mark]: https://cloud.google.com/text-to-speech/docs/ssml#mark

## License

Copyright 2020 Spokestack, Inc.
Copyright 2020 Bwisc B.V. (Botsquad).
Copyright 2021 Voiceworks B.V.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
