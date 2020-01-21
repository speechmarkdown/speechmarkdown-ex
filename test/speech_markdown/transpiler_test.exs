defmodule SpeechMarkdown.Transpiler.Test do
  use ExUnit.Case, async: true

  import SpeechMarkdown.Transpiler

  test "transpile" do
    assert transpile("") === {:ok, ~s|<?xml version="1.0"?><speak/>|}
    assert transpile!("text") === ~s|<?xml version="1.0"?><speak>text</speak>|

    # breaks
    assert transpile!("[200ms]") ===
             ~s|<?xml version="1.0"?><speak><break time="200ms"/></speak>|

    assert transpile!("[5s]") ===
             ~s|<?xml version="1.0"?><speak><break time="5s"/></speak>|

    # ipa
    assert transpile!("(pecan)[/pɪˈkɑːn/]") ===
             ~s|<?xml version="1.0"?><speak><phoneme alphabet="ipa" ph="pɪˈkɑːn">pecan</phoneme></speak>|

    # say-as
    assert transpile!("(www)[characters]") ===
             ~s|<?xml version="1.0"?><speak><say-as interpret-as="characters">www</say-as></speak>|

    assert transpile!("(1234)[number]") ===
             ~s|<?xml version="1.0"?><speak><say-as interpret-as="number">1234</say-as></speak>|
  end
end
