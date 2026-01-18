defmodule EventHorizonWeb.ResumeController do
  use EventHorizonWeb, :controller

  @filename "Aayush-Kumar-Sahu-Resume-2025.pdf"

  def show(conn, _params) do
    resume_path = Application.app_dir(:event_horizon, "priv/static/resume/#{@filename}")

    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header("content-disposition", ~s(inline; filename=#{@filename}))
    |> send_file(200, resume_path)
  end
end
