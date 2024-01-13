defmodule MdsWeb.Live.Login do
  use MdsWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="shadow-lg border py-10 px-3 w-full sm:w-3/4 mx-auto">
      <div class="text-center mb-5">
        Please log in with one of the providers below
      </div>

      <div class="flex flex-col gap-3 w-3/4 mx-auto">
        <.link navigate={~p"/auth/github"}>
          <button class="w-full bg-white hover:bg-gray-200 text-black rounded-lg py-2 px-3 text-sm font-medium border border-gray-300">
            Github
          </button>
        </.link>

        <.link navigate={~p"/auth/google"}>
          <button class="w-full bg-white hover:bg-gray-200 text-black rounded-lg py-2 px-3 text-sm font-medium border border-gray-300">
            Google
          </button>
        </.link>
      </div>
    </div>
    """
  end
end
