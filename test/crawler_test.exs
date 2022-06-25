defmodule CrawlerTest do
  use ExUnit.Case
  doctest Crawler

  test "greets the world" do
    assert Crawler.run() == :world
  end
end
