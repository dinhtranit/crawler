defmodule Crawler do
  @moduledoc """
  Documentation for `Crawler`.
  """

  @doc """
  Crawler download story from website www.medoctruyentranh.net.

  ## Examples
      iex> Crawler.run()
      :world
  """
  def run do
    download("https://www.medoctruyentranh.net/truyen-tranh/kingdom-vuong-gia-thien-ha-58664",
      '/Users/dinhtran/Downloads/')
  end

  def download(url, path) do
    referen = "#{URI.parse(url).scheme}://#{URI.parse(url).host}/"
    headers = [{"Referen", referen}]
    response = HTTPoison.get!(url,headers)

    {:ok, document} = Floki.parse_document(response.body)

    #prepare folder
    title = Floki.find(document, "#title") |> Floki.text()
    folder_name = "#{path}/#{URI.parse(url).host}/#{title}"

    #get list chapters
    chapters = document
      |> Floki.find(".chapters")
      |> Floki.find(".chapter_pages")
      |> Floki.find("a") |>  Enum.each(fn x -> x
        |> get_chapters(headers, folder_name)
      end)
  end

  def get_chapters(data_chapter, headers, folder_name) do
    if data_chapter do
      url = data_chapter
        |> Floki.attribute("href")
        |> List.first()
      get_story_pages(url, headers, folder_name)
    end
  end

  def get_story_pages(url, headers, folder_name) do
    response = HTTPoison.get!(url,headers)
    {:ok, document} = Floki.parse_document(response.body)

    detail_item = document |> Floki.find("script#__NEXT_DATA__")
      |> List.first()
      |> Tuple.to_list()
      |> Enum.at(2)
      |> List.first()
      |> Jason.decode!()
      |> Map.get("props")
      |> Map.get("pageProps")
      |> Map.get("initialState")
      |> Map.get("read")
      |> Map.get("detail_item")

    chapter_title = detail_item |> Map.get("chapter_title")

    chapter_folder = "#{folder_name}/#{chapter_title}"

    if not File.exists?(chapter_folder) do
      File.mkdir_p(chapter_folder)
    end

    url_pages = detail_item
      |> Map.get("elements")
      |> Enum.map(fn x -> x |> Map.get("content") end)

    download_story_page_img(url_pages, headers, chapter_folder, 0)
  end

  def download_story_page_img(url_pages, headers, chapter_folder, page_num) do
    if length(url_pages) > page_num do
      path_file_name = "#{chapter_folder}/page #{page_num + 1}.webp"
      if not File.exists?(path_file_name) do
        url = Enum.at(url_pages, page_num)
        response = HTTPoison.get!(url,headers)
        IO.inspect(path_file_name)
        File.write!(path_file_name, response.body)
        download_story_page_img(url_pages, headers, chapter_folder, page_num + 1)
      end
    end
  end
end
